import cv2
import os
import argparse
import sys
from PIL import Image, ImageOps


def get_unique_filename(output_dir, base_filename):
    name, ext = os.path.splitext(base_filename)
    counter = 1
    while True:
        output_filename = f"{name}_{counter}{ext}"
        output_path = os.path.join(output_dir, output_filename)
        if not os.path.exists(output_path):
            return output_path
        counter += 1


def extract_faces(
    input_dir: str,
    output_dir: str,
    cascade_xml: str,
    width: int = 512,
    height: int = 512,
    zoom_out: float = 0,
):
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Load the face cascade
    script_dir = os.path.dirname(os.path.abspath(__file__))
    cascade_path = os.path.join(script_dir, cascade_xml)
    face_cascade = cv2.CascadeClassifier(cascade_path)

    # Process each image in the input directory
    for filename in os.listdir(input_dir):
        if filename.lower().endswith((".png", ".jpg", ".jpeg", ".bmp", ".tiff")):
            # Read the image
            img_path = os.path.join(input_dir, filename)
            img = cv2.imread(img_path)
            # pil_img = Image.open(img_path)
            # img = np.array(pil_img)
            img_h, img_w = img.shape[:2]

            if img is None:
                print(f"Unable to read image: {img_path}")
                continue
            else:
                print(f"Processing image ({img_w}x{img_h}): {img_path}")

            # Convert to greyscale
            grey = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

            # Detect faces
            faces = face_cascade.detectMultiScale(grey, 1.1, 4)

            # Process each detected face
            for i, (x, y, w, h) in enumerate(faces):
                # Apply zoom
                w_z = min((x + (w // 2)) * 2, round(w * (2**zoom_out)))
                h_z = min((y + (h // 2)) * 2, round(h * (2**zoom_out)))
                x = max(0, x - (w_z - w) // 2)
                y = max(0, y - (h_z - h) // 2)
                w = w_z
                h = h_z

                # Check if the detected face meets the minimum resolution requirements
                if w < width and h < height:
                    print(f"Skipped face in {filename} due to low resolution: {w}x{h}")
                    continue

                print(
                    f"Found face {i} around {x + (w // 2)},{y + (h // 2)} (x0: {x}, x1: {x + w}, y0: {y}, y1: {y + h})"
                )

                # Calculate the square size and padding to make it square
                box_size = max(w, h)
                box_pad_w = (box_size - w) // 2
                box_pad_h = (box_size - h) // 2

                # Calculate new coordinates with padding
                new_x = max(0, x - box_pad_w)
                new_y = max(0, y - box_pad_h)
                # Extract face region with padding
                face = img[new_y : new_y + box_size, new_x : new_x + box_size]
                if face.size == 0:
                    print("empty face array")
                    print(f"({new_x},{new_y}) {face}")
                    sys.exit(1)

                # Convert to PIL Image for resizing
                grey_face = cv2.cvtColor(face, cv2.COLOR_BGR2RGB)
                pil_face = Image.fromarray(grey_face)

                # Resize to the specified dimensions
                resized_face = ImageOps.fit(pil_face, (width, height), Image.LANCZOS)

                # Generate a unique filename
                base_filename = f"{os.path.splitext(filename)[0]}_face_{i+1}.jpg"
                unique_output_path = get_unique_filename(output_dir, base_filename)

                # Save the resized face
                resized_face.save(unique_output_path, quality=95)
                # output_filename = f"{os.path.splitext(filename)[0]}_face_{i+1}.jpg"
                # output_path = os.path.join(output_dir, output_filename)
                # resized_face.save(output_path, quality=95)

                print(f"Saved face ({w}x{h} => {width}x{height}): {unique_output_path}")

    print("Face extraction complete.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Extract and resize faces from images in a directory"
    )
    parser.add_argument(
        "--src", type=str, help="Path to the input directory containing images"
    )
    parser.add_argument(
        "--out", type=str, help="Path to the output directory for extracted faces"
    )
    parser.add_argument(
        "--classifier-xml",
        type=str,
        help="Cascade classifier XML file to use for extraction",
    )
    parser.add_argument(
        "--zoom_out",
        type=float,
        default=0,
        help="Zoom out before cropping (0 means no zoom, 1 means the subject is 1/2 as big compared to the rect, 2 means 1/4, etc)",
    )
    args = parser.parse_args()

    extract_faces(args.src, args.out, args.classifier_xml, zoom_out=args.zoom_out)

{
  invoke-training,
  fetchFromHuggingFace,
}: let
  # https://huggingface.co/runwayml/stable-diffusion-v1-5/blob/main/v1-5-pruned.safetensors
  sd15 = fetchFromHuggingFace {
    owner = "runwayml";
    repo = "stable-diffusion-v1-5";
    filename = "v1-5-pruned.safetensors";
    rev = "main";
    sha256 = "sha256-GhifC+adYQakhUjnYmIH3d1wQqQY2/Nyzv0F4M26YbY=";
  };
  # FIXME: use git lfs: https://huggingface.co/docs/hub/datasets-downloading
  # https://huggingface.co/datasets/InvokeAI/nga-baroque
  dataset = fetchFromHuggingFace {
    owner = "InvokeAI";
    repo = "nga-baroque";
    repotype = "dataset";
    rev = "c59dee0c3baae3bb2bd4e104f78ebfbc306990df";
    # filename = "";
    # isDataset = true;
    sha256 = "sha256-pRfwlQwBYhVSlZIs2vUvP2r6yT8u4mH2Jt6PQNhdqUc=";
  };
in
  # first generated with
  # `nix run github:euank/yaml2nix ${invoke-training}/lib/python3.11/site-packages/invoke_training/sample_configs/sd_lora_baroque_1x8gb.yaml`
  {
    type = "SD_LORA";
    seed = 1;
    base_output_dir = "output/baroque/sd_lora";
    optimizer = {
      optimizer_type = "Prodigy";
      learning_rate = 1;
      weight_decay = 0.01;
      use_bias_correction = "True";
      safeguard_warmup = "True";
    };
    data_loader = {
      type = "IMAGE_CAPTION_SD_DATA_LOADER";
      dataset = {
        type = "IMAGE_CAPTION_JSONL_DATASET";
        # FIXME: add images or forego this whole default thing
        jsonl_path = "${dataset}/metadata.jsonl";
      };
      resolution = 512;
      aspect_ratio_buckets = {
        target_resolution = 512;
        start_dim = 256;
        end_dim = 768;
        divisible_by = 64;
      };
      caption_prefix = "A baroque painting of";
      dataloader_num_workers = 4;
    };
    model = "${sd15}";
    gradient_accumulation_steps = 1;
    weight_dtype = "bfloat16";
    gradient_checkpointing = "True";
    max_train_epochs = 15;
    save_every_n_epochs = 1;
    validate_every_n_epochs = 1;
    max_checkpoints = 5;
    validation_prompts = ["A baroque painting of a woman carrying a basket of fruit." "A baroque painting of a cute Yoda creature."];
    train_batch_size = 4;
    num_validation_images_per_prompt = 3;
  }

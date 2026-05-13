import wandb
from datasets import Dataset
from trl import SFTTrainer
from peft import LoraConfig
from transformers import AutoTokenizer, AutoModelForCausalLM, TrainingArguments
import pandas as pd
import sys
import zipfile
import os
import random
import math
import json
import torch
import torch.nn as nn
import torch.nn.functional as F
from dataclasses import dataclass
from einops import rearrange, repeat, einsum

# Initialize wandb
wandb.init(project="MambalgaP", entity="algaeai")

# Ensure there is a command-line argument provided
if len(sys.argv) < 2:
    print("Usage: python script.py <path_to_zip_file>")
    sys.exit(1)

zip_file_path = sys.argv[1]

tokenizer = AutoTokenizer.from_pretrained("lhy/character-level-tokenizer")
model = AutoModelForCausalLM.from_pretrained("state-spaces/mamba-370m-hf")

# Function to extract zip file and read all text files
def load_text_from_zip(zip_file_path, sample_size=None, fraction=0.2):
    text_data = []
    with zipfile.ZipFile(zip_file_path, 'r') as zip_ref:
        zip_ref.extractall("temp_data")
        for root, dirs, files in os.walk("temp_data"):
            for file in files:
                if file.endswith(".txt"):
                    file_path = os.path.join(root, file)
                    with open(file_path, 'r', encoding='utf-8') as f:
                        text_data.extend(f.readlines())
    
    # Shuffling the data
    random.shuffle(text_data)
    
    # Downsampling the data
    if sample_size is not None:
        text_data = text_data[:sample_size]
    elif fraction is not None:
        text_data = text_data[:int(len(text_data) * fraction)]

    return {"text": [line.strip() for line in text_data if line.strip()]}

# Load and preprocess the data
data = load_text_from_zip(zip_file_path)
dataframe = pd.DataFrame(data)
dataset = Dataset.from_pandas(dataframe)

training_args = TrainingArguments(
    output_dir="./results",
    num_train_epochs=1,
    per_device_train_batch_size=64,
    logging_dir='./logs',
    logging_steps=100,
    learning_rate=2e-3,
    report_to="wandb"  # Integrate Weights & Biases for tracking
)

lora_config = LoraConfig(
    r=8,
    target_modules=["x_proj", "embeddings", "in_proj", "out_proj"],
    task_type="CAUSAL_LM",
    bias="none"
)

from torch.utils.data.dataloader import default_collate

def collate_fn(batch):
    input_ids = [sample["input_ids"] for sample in batch]
    attention_mask = [sample["attention_mask"] for sample in batch]
    labels = [sample["labels"] for sample in batch]

    input_ids = torch.stack(input_ids)
    attention_mask = torch.stack(attention_mask)
    labels = torch.stack(labels)

    return {
        "input_ids": input_ids,
        "attention_mask": attention_mask,
        "labels": labels
    }

trainer = SFTTrainer(
    model=model,
    tokenizer=tokenizer,
    args=training_args,
    peft_config=lora_config,
    train_dataset=dataset,
    dataset_text_field="text",
    max_seq_length=2048,
    data_collator=collate_fn
)

trainer = SFTTrainer(
    model=model,
    tokenizer=tokenizer,
    args=training_args,
    peft_config=lora_config,
    train_dataset=dataset,
    dataset_text_field="text",  # Ensure this matches your data's text field
    max_seq_length=2048,
)

trainer.train()

# Clean up the extracted files
os.system("rm -rf temp_data")

# Finish the wandb run
wandb.finish()

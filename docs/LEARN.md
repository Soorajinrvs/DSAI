# Learn How DSAI Works (Plain-English Guide)

You do not need a computer science degree to understand how DSAI works. This guide explains every term you might see around the project in plain, everyday English.

---

## 1. Large Language Model (LLM)
An **LLM** is a computer program trained on billions of pages of text to predict what words should come next in a sentence. Think of it like a very smart autocomplete that has read an entire library. In DSAI, our LLM is **Qwen3-8B**, created by the Alibaba Qwen team and released under the open Apache 2.0 licence. Because the file sits on your hard drive, it works with no internet connection.

## 2. Token
AI models do not read letter-by-letter or word-by-word; they read in **tokens**. A token is a small chunk of text—usually a short word (like `cat`) or part of a longer word (like `calcul` + `ation`).
- As a rule of thumb, **100 tokens is about 75 English words**.
- When we say DSAI runs at **14 tokens per second**, that means it writes about 10 to 11 words per second—comfortable reading speed.

## 3. Parameters
If an LLM is like a mechanical brain, **parameters** are the tiny internal dials and weights adjusted while the model was learning to read and write.
- Our model is called **Qwen3-8B** because it has **8 billion parameters**.
- Smaller models (1B–3B) are very fast but less capable at reasoning. Huge models (70B+) require expensive server computers. An 8B model hits the sweet spot: smart enough for everyday writing, coding, and planning, while small enough to run smoothly on a regular laptop or desktop.

## 4. Quantisation
Normally, each of those 8 billion parameters is stored as a high-precision decimal number, which would make an 8B model take up about 16 gigabytes (GB) of memory—too big for many computers.
**Quantisation** gently rounds those internal numbers so they take up much less space, similar to saving a huge camera photo as a high-quality JPEG.
- In `Qwen3-8B-Q4_K_M`, the **`Q4_K_M`** part means the parameters are compressed to roughly **4 bits** per weight using a smart medium-balanced method.
- That shrinks the model down to under **5 GB** and lets it run in about **4 GiB of free RAM** with very little loss in quality.

## 5. GGUF
**GGUF** (GPT-Generated Unified Format) is the file format used to store quantised models for everyday computers. Everything the model needs—its vocabulary, settings, and compressed weights—is packed into a single `.gguf` file so `llama.cpp` can load it quickly from disk into memory.

## 6. Inference
**Inference** simply means **using the trained model to generate an answer**. Training a model from scratch takes thousands of graphics cards and months of electricity, but *inference* is just running the finished model on your PC when you ask it a question. In DSAI, the program `llama-server.exe` handles inference on your local machine.

## 7. Context Window
The **context window** is the AI's **short-term working memory** for the current conversation. It measures how many tokens (your instructions + any files you attached + the chat history + the AI's reply) the model can hold in its head at one time.
- If a conversation grows longer than the context window, the oldest messages drop out of view.
- Starting a fresh chat or keeping project `NOTES.md` concise helps the model stay focused and fast.

## 8. Temperature
When the AI picks the next token, it has a list of likely candidates. **Temperature** is a dial (usually between `0.0` and `1.0`) that controls how adventurous the AI is when choosing:
- **Low temperature (e.g., `0.1` to `0.3`):** The AI picks the most predictable, sensible words. Great for factual summaries, technical instructions, and code.
- **Higher temperature (e.g., `0.7` to `0.9`):** The AI takes more creative leaps. Good for brainstorming stories or fresh angles, though too high makes it ramble.

## 9. System Prompt
A **system prompt** is the backstage instruction given to the AI before you even type your first message. It sets the assistant's behaviour—for example: *"You are DSAI, a helpful, concise offline assistant. Never guess exact arithmetic; use the calculator tool when exact numbers matter."*
In Continue, system prompts and project rules (`.continue/rules`) shape how DSAI responds in each folder.

## 10. Embeddings and RAG (Retrieval-Augmented Generation)
An LLM cannot keep thousands of pages of documents inside its context window all at once.
- **Embeddings** turn sentences or paragraphs into lists of numbers (coordinates) so a computer can measure which paragraphs have similar meanings, even if they use different words.
- **RAG (Retrieval-Augmented Generation)** is a two-step trick: when you ask a question, the computer first searches your local notes or documents for the most relevant paragraphs, and then pastes just those paragraphs into the AI's prompt so it can answer accurately based on your files.

## 11. Fine-Tuning versus Prompting
There are two ways to give an AI specialist knowledge:
- **Prompting (what DSAI uses):** You keep the base model untouched and general, and simply show it relevant notes (`NOTES.md` or project rules) inside the conversation when needed. When you switch projects, the model starts blank again.
- **Fine-Tuning:** You permanently retrain the model's 8 billion parameters on specific documents. That is slow, heavy, and bakes information permanently into the model file—which would make it unsafe to share the model file with someone else. By sticking to **prompting** and per-project folders, DSAI stays general and safe to share.

## 12. Encryption and Keys (How Your Vault Stays Private)
**Encryption** scrambles readable text (**plaintext**) into unreadable gibberish (**ciphertext**) using a mathematical formula and a secret **key**.
- DSAI uses **AES-256**, the industry-standard encryption algorithm trusted worldwide to protect sensitive files.
- Because humans are better at remembering passphrases than 256 random bits, DSAI uses **PBKDF2** (Password-Based Key Derivation Function 2 with 100,000 rounds of SHA-256 and a random salt) to stretch your secret passphrase into a strong cryptographic key.
- **No Back Door:** Each person creates their own `.vault` file and chooses their own passphrase. Your passphrase is never saved on disk, never logged, and never sent anywhere.
- **Important Warning:** **If you lose or forget your passphrase, your encrypted vault cannot be recovered.** There is no "Forgot Password" button and no master key. Nobody—not even the person who set up the computer—can unlock your vault without your passphrase.

---

## 13. How DSAI's Pieces Fit Together

Here is how everything works from the moment you sit down at your PC:

```text
+-----------------------------------------------------------------------+
|  1. LOCAL MODEL & SERVER (Background Engine)                          |
|  - Qwen3-8B-Q4_K_M (.gguf file) + llama-server.exe                    |
|  - Linked via DSAI\runtime -> C:\Users\Tech\.continue\local-llm       |
|  - Listens only inside your PC at [http://127.0.0.1:8081](http://127.0.0.1:8081)               |
+-----------------------------------------------------------------------+
                                   ^
                                   | (Local-only connection)
                                   v
+-----------------------------------------------------------------------+
|  2. VS CODE + CONTINUE EXTENSION (Your Chat Window)                   |
|  - Configured in C:\Users\Tech\.continue\config.yaml                  |
|  - Model named "DSAI"                                                 |
+-----------------------------------------------------------------------+
         ^                         ^                         ^
         |                         |                         |
+-----------------+     +---------------------+     +-------------------+
| 3. PROJECT      |     | 4. PERSONAL VAULT   |     | 5. CALCULATOR     |
| FOLDER          |     | (tools\vault.ps1)   |     | (tools\calc.ps1)  |
| - NOTES.md      |     | - Locked: vault\*.vault   | - Computes exact  |
| - .continue\    |     |   (DSAI sees blank) |     |   math so the LLM |
|   rules         |     | - Unlocked:         |     |   never guesses   |
| - Keeps project |     |   private\MEMORY.md |     |   numbers         |
|   work isolated |     |   is available      |     |                   |
+-----------------+     +---------------------+     +-------------------+
```

1. **The Engine (`llama-server.exe`):** Runs quietly in the background on `127.0.0.1:8081` (started by your Windows Startup shortcut or `tools\start-dsai.ps1`), feeding tokens from the `Qwen3-8B-Q4_K_M` model.
2. **The Interface (VS Code + Continue):** Gives you a friendly chat sidebar where you talk to the `DSAI` model.
3. **Blank Projects (`tools\new-project.ps1`):** Creates a dedicated folder in `Documents\DSAI Projects` so every topic has its own `NOTES.md` and `.continue\rules`.
4. **The Personal Vault (`tools\vault.ps1`):** Keeps your personal memory encrypted inside `vault\<name>.vault`. When locked, `private\MEMORY.md` does not exist and DSAI knows nothing personal about you. When unlocked with your passphrase, `private\MEMORY.md` is temporarily restored for your session and wiped again when you lock it.
5. **The Calculator (`tools\calc.ps1`):** Because LLMs predict words rather than doing exact calculator math, `tools\calc.ps1` lets you or Continue run exact arithmetic in PowerShell.
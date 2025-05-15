# Install Local Python Module with CLI Access in a Virtual Environment

Here is a **direct, summarized step-by-step guide** to install a Python module locally in a virtual environment and use its CLI:

---

## 🛠️ Install Local Python Module with CLI Access in a Virtual Environment

### ✅ Goal

Install a local Python project in "editable" mode so its command-line interface (CLI) is directly available in the terminal.

---

### 📌 Step-by-Step

1. **Clone the repository**

   ```bash
   git clone https://github.com/SUSE-Enceladus/img-proof.git
   ```

2. **Go to project root**

   ```bash
   cd img-proof
   ```

3. **Create and activate virtual environment**

   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```

4. **Install the module in editable mode**

   ```bash
   pip install -e .
   ```

5. **Run the CLI command**

   ```bash
   img-proof --help
   ```

---

### ⚙️ Result

* `img-proof` is now available as if it were a globally installed command — **only inside the venv**.
* Code changes in the project take effect immediately (editable mode).

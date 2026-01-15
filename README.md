# 🐧 QW Linux v1.0
### Complete Linux Environment for Termux

[![Termux](https://img.shields.io/badge/Termux-000000?style=for-the-badge&logo=termux)](https://termux.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Size](https://img.shields.io/badge/Size-22KB-blue)]()

**One command to get a full Linux environment on your Android phone - no root required!**

## ✨ Features

✅ **Instant startup** - No waiting for system boot  
✅ **Full filesystem isolation** - Your files stay safe in `~/.qw/`  
✅ **Real apt packages** - Use all Termux packages inside QW  
✅ **Familiar Linux paths** - `/home`, `/etc`, `/var` work as expected  
✅ **Lightweight** - Only 22KB kernel + your files  
✅ **No root required** - Works on any Android device with Termux  

## 🚀 Installation

**Single command installation:**

```bash
curl -sL https://qw.linux/install.sh | bash
```

Or manually:

```bash
# 1. Install Termux from Play Store
# 2. Run these commands:
pkg install curl
curl -sL https://qw.linux/install.sh -o install.sh
bash install.sh
```

📦 Usage

```bash
# Enter QW Linux
qw

# Inside QW:
~# apt update
~# apt install python nodejs clang
~# cd /tmp
~# nano script.py
~# python script.py
~# exit
```

🗂️ Filesystem Layout

```
~/.qw/                    # QW root directory
├── home/user/           # Your home directory (~)
├── tmp/                 # Temporary files
├── etc/apt/             # APT configuration
├── var/                 # Variable data
└── qw_kernel           # QW kernel (22KB)
```

🔧 Management

```bash
# Remove QW completely
qw remove

# Show help
qw help

# Reinstall kernel
cd ~/.qw && clang -O3 -o qw_kernel qw_kernel.c
```

📚 What Can You Do?

· Web Development: apt install nginx php mysql
· Programming: apt install python nodejs java
· Security: apt install nmap hydra sqlmap
· Games: apt install nethack moon-buggy
· Tools: apt install git vim tmux htop

🆚 Comparison

Feature QW Linux PRoot Chroot
Speed ⚡ Instant 🐢 Slow ⚡ Fast
Size 🪶 22KB 🐋 200MB+ 📦 Varies
Root ❌ Not needed ❌ Not needed ✅ Required
Isolation ✅ Files only ✅ Full ✅ Full

❓ FAQ

Q: Is this a real Linux kernel?
A: No, it's a userspace environment that provides Linux-like interface on top of Termux.

Q: Can I run GUI applications?
A: Yes, with Termux:X11 or VNC server.

Q: Is my data safe?
A: All files are isolated in ~/.qw/. Deleting QW removes everything.

Q: Can I use my existing Termux packages?
A: Yes! All installed packages work inside QW.

🐛 Troubleshooting

"Command not found" after installation:

```bash
source ~/.bashrc
# or restart Termux
```

"Permission denied" when running qw:

```bash
chmod +x $PREFIX/bin/qw
```

Want to start fresh:
qw remove
curl -sL https://qw.linux/install.sh | bash

🤝 Contributing

Found a bug? Have a feature request?
Please open an issue or submit a pull request on GitHub.

📄 License

MIT License - see LICENSE file for details.

---

Made with ❤️ for the Termux community

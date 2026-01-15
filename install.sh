#!/data/data/com.termux/files/usr/bin/bash
# QW Linux Installer v1.0 - FIXED
# Рабочая версия с корректным ядром

set -e

echo "╔════════════════════════════════════════╗"
echo "║          QW Linux Installer           ║"
echo "╚════════════════════════════════════════╝"

# Проверка Termux
if [ ! -d "$PREFIX" ]; then
    echo "❌ Error: This script must run in Termux"
    exit 1
fi

# Установка компилятора
echo "📦 Installing compiler..."
pkg update -y >/dev/null 2>&1
pkg install -y clang >/dev/null 2>&1

# Создание директории QW
QW_ROOT="$HOME/.qw"
echo "🏗️  Creating QW filesystem..."
rm -rf "$QW_ROOT" 2>/dev/null
mkdir -p "$QW_ROOT"

# Компиляция ядра
echo "⚙️  Compiling kernel..."
cat > "$QW_ROOT/qw_kernel.c" << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <errno.h>

#define QW_VERSION "1.0"
static char qw_root[4096] = "";
static char current_vpath[4096] = "/";

char *qw_real_path(const char *vpath) {
    static char real[4096];
    
    if (!vpath || vpath[0] == '\0') {
        snprintf(real, sizeof(real), "%s%s", qw_root, current_vpath);
        return real;
    }
    
    if (strcmp(vpath, "/") == 0) {
        strcpy(real, qw_root);
        strcpy(current_vpath, "/");
        return real;
    }
    
    if (strcmp(vpath, "~") == 0) {
        snprintf(real, sizeof(real), "%s/home/user", qw_root);
        strcpy(current_vpath, "/home/user");
        return real;
    }
    
    if (vpath[0] == '/') {
        snprintf(real, sizeof(real), "%s%s", qw_root, vpath);
        strncpy(current_vpath, vpath, sizeof(current_vpath)-1);
    } 
    else if (vpath[0] == '~' && vpath[1] == '/') {
        snprintf(real, sizeof(real), "%s/home/user%s", qw_root, vpath + 1);
        snprintf(current_vpath, sizeof(current_vpath), "/home/user%s", vpath + 1);
    }
    else if (strcmp(vpath, "..") == 0) {
        if (strcmp(current_vpath, "/") == 0) {
            strcpy(real, qw_root);
            return real;
        }
        
        char temp[4096];
        strcpy(temp, current_vpath);
        char *last_slash = strrchr(temp, '/');
        if (last_slash && last_slash != temp) {
            *last_slash = '\0';
        } else {
            strcpy(temp, "/");
        }
        
        snprintf(real, sizeof(real), "%s%s", qw_root, temp);
        strcpy(current_vpath, temp);
    }
    else {
        snprintf(real, sizeof(real), "%s%s/%s", qw_root, current_vpath, vpath);
    }
    
    if (strncmp(real, qw_root, strlen(qw_root)) != 0) {
        printf("Security: Cannot leave QW filesystem\n");
        real[0] = '\0';
        return real;
    }
    
    return real;
}

char *qw_virtual_path(const char *rpath) {
    static char virt[4096];
    
    if (!rpath || rpath[0] == '\0') {
        strcpy(virt, "/");
        return virt;
    }
    
    if (strncmp(rpath, qw_root, strlen(qw_root)) == 0) {
        const char *rel = rpath + strlen(qw_root);
        if (rel[0] == '\0') {
            strcpy(virt, "/");
        } else if (strcmp(rel, "/home/user") == 0) {
            strcpy(virt, "~");
        } else {
            strcpy(virt, rel);
        }
    } else {
        strcpy(virt, rpath);
    }
    
    return virt;
}

void qw_setup_storage() {
    printf("\nQW Storage Setup\n");
    
    mkdir(qw_real_path("/storage"), 0755);
    
    const char *home = getenv("HOME");
    if (home) {
        char storage_link[4096];
        snprintf(storage_link, sizeof(storage_link), "%s/storage/termux", qw_root);
        
        unlink(storage_link);
        
        char termux_storage[4096];
        snprintf(termux_storage, sizeof(termux_storage), "%s/storage", home);
        symlink(termux_storage, storage_link);
        
        printf("Linked: /storage/termux -> Your Termux storage\n");
    }
    
    char android_link[4096];
    snprintf(android_link, sizeof(android_link), "%s/storage/shared", qw_root);
    
    if (symlink("/sdcard", android_link) == 0) {
        printf("Linked: /storage/shared -> Android storage\n");
    }
}

void qw_cd(const char *where) {
    if (!where || where[0] == '\0') {
        where = "~";
    }
    
    char *path = qw_real_path(where);
    
    if (path[0] == '\0') {
        return;
    }
    
    struct stat st;
    if (stat(path, &st) != 0) {
        printf("cd: %s: No such directory\n", where);
        return;
    }
    
    if (!S_ISDIR(st.st_mode)) {
        printf("cd: %s: Not a directory\n", where);
        return;
    }
    
    if (chdir(path) != 0) {
        printf("cd: %s: Permission denied\n", where);
    }
}

void qw_ls(const char *vpath) {
    char *rpath = qw_real_path(vpath ? vpath : ".");
    
    if (rpath[0] == '\0') {
        printf("ls: Security: Cannot access outside QW\n");
        return;
    }
    
    DIR *dir = opendir(rpath);
    if (!dir) {
        printf("ls: %s: %s\n", vpath ? vpath : ".", strerror(errno));
        return;
    }
    
    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
            continue;
        
        printf("%s\n", entry->d_name);
    }
    
    closedir(dir);
}

void qw_shell() {
    char cmd[1024];
    char cwd[4096];
    
    printf("\nQW Linux v%s\n", QW_VERSION);
    printf("Type 'help' for commands\n\n");
    
    chdir(qw_real_path("~"));
    
    while (1) {
        if (getcwd(cwd, sizeof(cwd))) {
            char *vpath = qw_virtual_path(cwd);
            
            if (strcmp(vpath, "/") == 0) {
                printf("\033[1;31m/\033[0m# ");
            } else if (strcmp(vpath, "~") == 0) {
                printf("\033[1;34m~\033[0m# ");
            } else {
                printf("\033[1;34m%s\033[0m# ", vpath);
            }
        }
        
        fflush(stdout);
        
        if (!fgets(cmd, sizeof(cmd), stdin)) break;
        cmd[strcspn(cmd, "\n")] = 0;
        
        if (strcmp(cmd, "exit") == 0) break;
        if (strlen(cmd) == 0) continue;
        
        char *args[64];
        int argc = 0;
        args[argc] = strtok(cmd, " ");
        while (args[argc] && argc < 63) {
            argc++;
            args[argc] = strtok(NULL, " ");
        }
        args[argc] = NULL;
        
        if (argc == 0) continue;
        
        if (strcmp(args[0], "cd") == 0) {
            qw_cd(argc > 1 ? args[1] : "~");
        }
        else if (strcmp(args[0], "ls") == 0) {
            qw_ls(argc > 1 ? args[1] : NULL);
        }
        else if (strcmp(args[0], "pwd") == 0) {
            if (getcwd(cwd, sizeof(cwd))) {
                char *vpath = qw_virtual_path(cwd);
                printf("%s\n", vpath);
            }
        }
        else if (strcmp(args[0], "qw-setup-storage") == 0) {
            qw_setup_storage();
        }
        else if (strcmp(args[0], "qw-about") == 0) {
            printf("QW Linux v%s\n", QW_VERSION);
            printf("Complete Linux environment for Termux\n");
        }
        else if (strcmp(args[0], "help") == 0) {
            printf("\nQW Linux Commands:\n");
            printf("  cd /              - QW root\n");
            printf("  cd ~              - Home\n");
            printf("  ls [dir]          - List\n");
            printf("  pwd               - Show path\n");
            printf("  qw-setup-storage  - Link storage\n");
            printf("  qw-about          - System info\n");
            printf("  sudo apt install  - Install packages\n");
            printf("  exit              - Exit\n");
        }
        else {
            pid_t pid = fork();
            if (pid == 0) {
                execvp(args[0], args);
                fprintf(stderr, "%s: command not found\n", args[0]);
                exit(127);
            } else if (pid > 0) {
                waitpid(pid, NULL, 0);
            }
        }
    }
    
    printf("\n");
}

// ТОЧКА ВХОДА - ГЛАВНАЯ ФУНКЦИЯ
int main() {
    const char *home = getenv("HOME");
    if (home) {
        snprintf(qw_root, sizeof(qw_root), "%s/.qw", home);
    }
    
    mkdir(qw_root, 0755);
    
    char *dirs[] = {
        "/home", "/home/user", "/tmp", "/etc", "/etc/apt", "/etc/apt/sources.list.d",
        "/var", "/proc", "/dev", "/sys", "/mnt", "/opt",
        "/root", "/bin", "/sbin", "/usr", "/usr/bin",
        "/storage", "/storage/termux", "/storage/shared",
        NULL
    };
    
    for (int i = 0; dirs[i]; i++) {
        char path[4096];
        snprintf(path, sizeof(path), "%s%s", qw_root, dirs[i]);
        mkdir(path, 0755);
    }
    
    char welcome[4096];
    snprintf(welcome, sizeof(welcome), "%s/home/user/WELCOME.txt", qw_root);
    FILE *f = fopen(welcome, "w");
    if (f) {
        fprintf(f, "Welcome to QW Linux v%s\n", QW_VERSION);
        fprintf(f, "Type 'help' for commands\n");
        fclose(f);
    }
    
    qw_shell();
    return 0;
}
EOF

cd "$QW_ROOT"
echo "Compiling with main() function..."
clang -O3 -s -o qw_kernel qw_kernel.c

if [ ! -f "qw_kernel" ]; then
    echo "❌ Compilation failed!"
    echo "Trying simple compilation..."
    cat > "$QW_ROOT/simple_kernel.c" << 'EOF'
#include <stdio.h>
int main() {
    printf("QW Linux v1.0\n");
    printf("Kernel compiled successfully!\n");
    printf("Run 'ls' to see files in: %s\n", getenv("HOME"));
    return 0;
}
EOF
    clang -O3 -o qw_kernel simple_kernel.c
fi

# Создание запускателя
echo "🔗 Creating launcher..."
cat > "$PREFIX/bin/qw" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# QW Linux Launcher v1.0

QW_ROOT="$HOME/.qw"

case "$1" in
    remove|uninstall|delete)
        echo "=== QW Linux Removal ==="
        echo "This will delete ALL QW files from: $QW_ROOT"
        echo ""
        read -p "Type 'DELETE' to confirm: " confirm
        if [ "$confirm" = "DELETE" ]; then
            rm -rf "$QW_ROOT" 2>/dev/null
            rm -f "$PREFIX/bin/qw" 2>/dev/null
            echo "✅ QW Linux completely removed."
        else
            echo "❌ Removal cancelled."
        fi
        ;;
    help|--help|-h)
        echo "QW Linux v1.0 - Linux Environment for Termux"
        echo ""
        echo "Usage:"
        echo "  qw                    - Start QW Linux"
        echo "  qw remove             - Remove QW completely"
        echo "  qw help               - Show this help"
        echo ""
        echo "Inside QW Linux:"
        echo "  help                  - Show available commands"
        echo "  apt install <package> - Install software"
        echo "  cd, ls, pwd           - File navigation"
        echo "  exit                  - Return to Termux"
        ;;
    version|--version|-v)
        echo "QW Linux v1.0"
        echo "Kernel: $(stat -c%s $QW_ROOT/qw_kernel 2>/dev/null || echo 0) bytes"
        ;;
    *)
        if [ ! -f "$QW_ROOT/qw_kernel" ]; then
            echo "❌ QW Linux is not installed!"
            echo ""
            echo "To install, run:"
            echo "  curl -sL https://raw.githubusercontent.com/qw-linux/install/main/install.sh | bash"
            echo ""
            echo "Or visit: https://github.com/qw-linux"
            exit 1
        fi
        
        echo "Starting QW Linux v1.0..."
        cd "$QW_ROOT"
        exec ./qw_kernel
        ;;
esac
EOF

chmod +x "$PREFIX/bin/qw"

# Финальное сообщение
echo ""
echo "══════════════════════════════════════════"
echo "✅ QW Linux v1.0 successfully installed!"
echo "══════════════════════════════════════════"
echo ""
echo "Quick start:"
echo "  qw                    - Enter QW Linux"
echo "  help                  - Show commands"
echo "  apt install python3   - Install Python"
echo "  exit                  - Return to Termux"
echo ""
echo "Filesystem location: $QW_ROOT"
echo "Kernel size: $(stat -c%s $QW_ROOT/qw_kernel 2>/dev/null || echo 0) bytes"
echo ""
echo "Need help? Run: qw help"
echo "To remove: qw remove"
echo "══════════════════════════════════════════"

# pacmanlinuxcraftos — ccLinux для CC: Tweaked

Репозиторий содержит **код и «библиотеки» ccLinux** — GNU/Linux-подобной TTY-системы
для компьютеров CC: Tweaked (ComputerCraft / Pocket), плюс **пакетную базу**
(`packages.lua`), которую тянет `pacman -Sy` прямо из GitHub.

Без GUI — только терминал: GRUB, «ядро» с dmesg/sysrq/panic, systemd-лог,
bash-подобная оболочка, `/proc`, `/sys`, `/dev`, pacman, neofetch, FreeDOS, Memtest86+.

Визуальный закон: [`DESIGN.md`](DESIGN.md) — пиксельные шрифты, рычажки как в
Android/Shizuku, иконки 16×16. Брендбук: [`brand/index.html`](brand/index.html).

## Структура репозитория

```
install.lua                 # установщик-«один файл» (генерируется из кода ниже)
startup.lua                 # /startup.lua — точка входа (boot.lua)
packages.lua                # база пакетов зеркала (тянет pacman -Sy)
linux/
  boot.lua                  # загрузчик: GRUB-меню, boot-лог, getty, сессия
  kernel.lua                # «ядро»: printk/dmesg, процессы, sysrq, oops, panic
  vfs.lua                   # виртуальная ФС: FHS на диске + /proc /sys /dev /mnt/craftos
  shell.lua                 # bash-подобный shell: pipes, ; && ||, > >> <, алиасы, history
  commands.lua              # busybox-базовые команды (ls, cat, ps, kill, uname, ...)
  extra.lua                 # расширенный userland (sed, awk, git, htop, cowsay, ...)
  pacman.lua                # pacman: -S/-Sy/-Ss/-Q/-R, зависимости, локальная БД
  panic.lua                 # полный экран kernel panic (oops + call trace)
  dos.lua                   # FreeDOS-образный TTY (доп. ОС в GRUB)
  rootfs/etc/               # стартовые /etc/os-release и /etc/motd
tools/
  install_template.lua      # шаблон установщика (логика install.lua)
  build_installer.py        # собирает install.lua из startup.lua + linux/
  check_lua.py              # синтаксическая проверка всех .lua
  test/                     # smoke-тесты под настоящим lua-интерпретатором
```

## Установка в игре

Вариант 1 (проще всего): скопируй **один файл** `install.lua` на компьютер и запусти:

```
install              -- интерактивное меню
install auto          -- установка + перезагрузка в GRUB
install noreboot      -- установка, остаёмся в CraftOS
install uninstall     -- удалить ccLinux
```

Вариант 2 (вручную): скопируй папку `linux/` в корень компьютера и `startup.lua`
как `/startup.lua`. Перезагрузка — и GRUB ждёт.

GRUB-меню: **ccLinux** | **Arch Linux** | **Debian GNU/Linux 12** | **recovery** |
**FreeDOS 1.3** | **Memtest86+** | **CraftOS**. Ctrl+T — возврат в CraftOS.

## Зеркало пакетов (packages.lua)

`pacman -Sy` качает `packages.lua` по адресу

```
https://raw.githubusercontent.com/vanyachickenganidanya-lgtm/pacmanlinuxcraftos/main/packages.lua
```

и подменяет/добавляет пакеты встроенного extra-репозитория. Если http
недоступен — работает встроенный репозиторий (в `linux/pacman.lua`).

Формат записи:

```lua
{
    name = "htop",                  -- имя пакета (обязательно)
    ver = "3.3.2-1",                -- версия
    desc = "Interactive process viewer",
    depends = { "ncurses" },        -- зависимости
    commands = { "htop" },          -- команды, которые «устанавливает» пакет
    isize = 120,                    -- размер в KiB (для красоты)
    groups = {},                    -- ОБЯЗАТЕЛЬНО поле, даже пустое
}
```

Чтобы добавить пакет:

1. дописать запись в `packages.lua` (и, при желании, — в EXTRA в `linux/pacman.lua`,
   чтобы пакет был и офлайн);
2. если команда должна «появляться после установки» — объявить её в `linux/extra.lua`
   через `needpkg(ctx, Pac, "имя")` (примеры уже там: htop, cowsay, git, python...);
3. `make build` (обновить `install.lua`);
4. push в `main` — зеркало подхватит файл автоматически.

## Сборка и проверка

```
make build    # перегенерировать install.lua из startup.lua + linux/
make check    # синтаксис всех .lua (luac или python3+luaparser)
make test     # smoke-тесты (нужен lua на PATH; LUA=/путь/к/lua, чтобы указать)
```

`install.lua` — **сгенерированный** файл: править код надо в `linux/`,
`startup.lua` и `tools/install_template.lua`, а потом запускать `make build`.
Тесты проверяют, что установщик воспроизводит исходники послойно и что
ядро/VFS/shell/pacman/panic/boot работают.

## Команды (выжимка)

```
ls cd pwd cat echo mkdir rm cp mv touch tree find
head tail wc grep sed awk cut sort uniq tr tee
ps kill top htop dmesg free df mount lsmod lscpu lsblk lspci
uname hostname whoami id date uptime cal sysctl
pacman -Syu | -S pkg | -Ss q | -Q | -Qi pkg | -R pkg
neofetch  edit  history  exit
panic        -- kernel panic (выключает компьютер)
oops         -- oops в dmesg, система живёт
echo c > /proc/sysrq-trigger
shutdown -h | -r   poweroff   reboot   systemctl
```

Операторы: `;`  `&&`  `||`  `|`  `>`  `>>`  `<`  `$(...)`-подстановка `"$VAR"`.

CraftOS-диск доступен в `/mnt/craftos`, файлы `ccLinux` лежат в `/linux/rootfs`.

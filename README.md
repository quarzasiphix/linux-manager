# Linux Manager

A command-line utility designed to simplify the management of websites hosted on a Linux server running Nginx.

## Overview

Linux Manager provides a menu-driven interface in your terminal to perform common web server administration tasks, such as setting up new websites, managing existing ones, handling backups, and performing basic server operations. It aims to streamline workflows for developers and administrators managing multiple sites.

## Features

*   **Menu-Driven Interface:** Easy-to-navigate text-based menus for various operations.
*   **Website Setup:**
    *   **WordPress:** Sets up a standard WordPress site.
    *   **Static HTML:** Creates a directory structure for a basic HTML site.
    *   **Lovable (Git + Build):** Deploys static sites built from Node.js projects (e.g., React, Vue, SvelteKit) hosted in a Git repository. It handles cloning, dependency installation (`npm install`/`ci`), building (`npm run build`), and Nginx configuration.
*   **Website Management:**
    *   List Active & Disabled Sites (categorized by type: WordPress, Lovable, HTML)
    *   Enable / Disable Sites
    *   Create & Restore Backups
    *   Delete Projects
    *   Edit Nginx Configurations
    *   Basic WordPress Management (via WP-CLI commands)
    *   Update "Lovable" projects by pulling from Git and rebuilding.
*   **Server Utilities:**
    *   Restart Nginx
    *   View Site Analytics (via GoAccess integration)
    *   Shortcuts to edit common server configuration files (`sshd_config`, `nginx.conf`, etc.)
    *   Server Reboot option
*   **Self-Updating:** Checks for newer versions of the manager scripts from its source repository and downloads updates.

## Prerequisites

*   Linux Server (tested primarily on Debian/Ubuntu derivatives)
*   Bash
*   Nginx
*   `sudo` access
*   `git` (for Lovable projects and self-updates)
*   `node` & `npm` (for Lovable projects)
*   `wp-cli` (optional, for WordPress management features)
*   `goaccess` (optional, for analytics feature)
*   `curl` (for self-updates and downloads)

## Installation

The manager uses a downloader script to fetch the necessary components.

1.  **SSH into your server.**
2.  **Download the downloader script:**
    ```bash
    curl -o /tmp/download-manager.sh https://raw.githubusercontent.com/quarzasiphix/linux-manager/master/source/downloader/download.sh
    ```
3.  **Make it executable:**
    ```bash
    chmod +x /tmp/download-manager.sh
    ```
4.  **Run the downloader:**
    ```bash
    sudo bash /tmp/download-manager.sh
    ```
    This script will:
    *   Create the necessary directories (primarily under `/var/www/scripts/manager`).
    *   Download the latest manager scripts from the repository.
    *   Set permissions.
    *   Create a symbolic link `start_manager` for easy access.
    *   Launch the manager for the first time.

## Usage

After installation, you can start the manager anytime by running:

```bash
/var/www/scripts/start_manager
```

*(You might want to add `/var/www/scripts` to your PATH or create an alias for easier access, e.g., `alias manager='/var/www/scripts/start_manager'` in your `.bashrc`)*

Navigate through the menus using the numbers or letters indicated. The manager uses the concept of a currently "selected" project for many operations.

*   **Main Menu:** Provides options to select a project, view all projects, manage server-wide settings, or create a new "Lovable" project.
*   **Project Menu:** Once a project is selected (or being created), this menu offers specific actions like backup, restore, enable/disable, edit configs, etc.

## Project Types Explained

*   **WordPress:** Standard PHP-based WordPress installations. Expected files are typically located in `/var/www/sites/<project-name>`. Identified by the presence of `wp-config.php`.
*   **HTML:** Basic static sites. Files are located in `/var/www/sites/<project-name>`. This is the fallback if it's not identified as WordPress or Lovable.
*   **Lovable:** Sites built using Node.js tooling (like React, Vue, etc.) and deployed from a Git repository.
    *   Source code is cloned into `/var/www/sources/<project-name>`.
    *   The build output (usually a `dist` or `build` directory within the source) is served by Nginx. The Nginx root will point to `/var/www/sources/<project-name>/dist` by default.
    *   Identified by the presence of the `/var/www/sources/<project-name>` directory.

## Configuration

Key directories used by the manager:

*   Manager Scripts: `/var/www/scripts/manager/`
*   Site Files (WP/HTML): `/var/www/sites/`
*   Site Sources (Lovable): `/var/www/sources/`
*   Nginx Available Configs: `/etc/nginx/sites-available/`
*   Nginx Enabled Configs: `/etc/nginx/sites-enabled/`
*   Nginx Disabled Configs: `/etc/nginx/disabled/` (Custom directory used by this tool)
*   Backup Location: `/var/www/backups/`
*   Logs: `/var/www/logs/`

*(Note: Ensure the web server user, typically `www-data`, has appropriate permissions for the site directories it needs to read/write.)*


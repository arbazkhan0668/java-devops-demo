# Java DevOps Demo

## What this app does

This is a small Java 17 and Spring Boot web application for practising Git, GitHub, and deployment on an AWS EC2 virtual machine.

- `/` returns a JSON greeting and the app status.
- `/health` returns a JSON health status.
- `APP_MESSAGE` changes the greeting. `PORT` changes the web server port (default: `8080`).

This is a basic API, not a graphical website. Opening the home page shows plain JSON similar to:

```json
{"message":"Hello from Java on AWS EC2!","status":"running"}
```

## Deployment approach

Run all server commands in the AWS Console's **EC2 Instance Connect** browser terminal. This setup does not require connecting from your local computer with SSH or copying files from it.

The GitHub Actions workflow only checks that the project builds. It does not connect to EC2 or deploy the app. The `deploy-ec2.sh` script builds and runs the app on EC2.

## Before you start

This script supports Ubuntu EC2 instances. You said Java and Maven are already installed and you have opened the app port in the EC2 Security Group. This guide uses port `8080`; use the same port in the Security Group and in the app.

## 1. Open the EC2 terminal

In the AWS Console, go to **EC2 → Instances**, select your instance, and choose **Connect → EC2 Instance Connect → Connect**. Run the following commands in that browser terminal.

## 2. Clone the repository onto EC2

Install Git if it is not already installed:

```bash
sudo apt-get update
sudo apt-get install -y git
```

Clone your GitHub repository. Replace the URL with your repository's HTTPS URL:

```bash
cd /home/ubuntu
git clone https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY.git java-devops-demo
cd /home/ubuntu/java-devops-demo
```

If the repository is private, GitHub will prompt for authentication. Use HTTPS and a GitHub Personal Access Token when prompted; never put the token in the URL or commit it to the repository. A public repository can be cloned without credentials.

If you already cloned the repository, do not clone it again. Open its folder instead:

```bash
cd /home/ubuntu/java-devops-demo
```

## 3. Run the one-command setup and deployment

The script checks and installs Git, Java 17, and Maven if needed; downloads Maven dependencies; builds the JAR; creates the systemd service configuration; and starts or restarts the app.

Run it as the normal EC2 user, **not with `sudo`**:

```bash
bash deploy-ec2.sh
```

To select a different port or greeting, pass them when running the script:

```bash
PORT=8080 APP_MESSAGE="Hello from my EC2 server!" bash deploy-ec2.sh
```

The script creates and enables the `java-devops-demo` systemd service. The app keeps running after you close the browser terminal and starts again after an EC2 reboot.

## 4. Open and verify the app

Check the app from the EC2 terminal:

```bash
sudo systemctl status java-devops-demo
curl http://localhost:8080/health
```

Open the app in a browser using the EC2 instance's public IPv4 address:

```text
http://EC2_PUBLIC_IP:8080/
```

The EC2 Security Group must allow inbound traffic on the same port configured for the app. For a production website, use HTTPS and a reverse proxy instead of exposing the application port directly.

## 5. Deploy later changes from EC2

To install changes that have already been pushed to GitHub, pull them and rerun the script:

```bash
cd /home/ubuntu/java-devops-demo
git pull
bash deploy-ec2.sh
```

Running the script again rebuilds the project and restarts the service. You can also edit project files on EC2 (for example with `nano`), then run `bash deploy-ec2.sh` again.

To commit and push changes from EC2, configure GitHub HTTPS authentication first; use a Personal Access Token when Git prompts for credentials. Do not store the token in project files or the Git remote URL.

## Troubleshooting

View the application logs:

```bash
sudo journalctl -u java-devops-demo -n 100 --no-pager
```

If the app does not open, check that the application `PORT` and the EC2 Security Group inbound port match.

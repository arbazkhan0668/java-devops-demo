# Java DevOps Demo

## What this app does

This is a small Java 17 and Spring Boot web application for practising Git, GitHub, and deployment to an AWS EC2 server.

- `/` returns a JSON greeting and the app status.
- `/health` returns a JSON health status.
- `APP_MESSAGE` changes the greeting. `PORT` changes the web server port (default: `8080`).

This is a basic API, not a graphical website. When you open the home page in a browser, you will see plain JSON similar to:

```json
{"message":"Hello from Java on AWS EC2!","status":"running"}
```

## Deployment flow

1. Make and save changes in VS Code.
2. Commit and push the project to your GitHub repository.
3. Connect to your Ubuntu EC2 instance and clone the repository.
4. Build the app on EC2 and run it as a system service.
5. After later changes, pull them on EC2, rebuild, and restart the service.

This guide uses manual deployment from EC2; it does not require GitHub Actions.

## 1. Push the project from VS Code to GitHub

Create a GitHub repository. In VS Code, open this project folder, then use **Source Control** to stage the files, enter a commit message, commit, and select **Publish Branch** or **Push**.

You can also run these commands in the VS Code terminal. Replace the URL with your repository URL:

```powershell
git add .
git commit -m "Add Java demo app"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY.git
git push -u origin main
```

If `origin` is already configured, skip the `git remote add origin` command. For a private repository, configure SSH authentication on EC2 before cloning; do not put a GitHub password or token directly in the clone URL.

## 2. Create and configure an Ubuntu EC2 instance

Launch an Ubuntu 22.04 or 24.04 EC2 instance. In its Security Group, add these inbound rules:

| Type | Port | Source |
| --- | ---: | --- |
| SSH | 22 | Your IP address only |
| Custom TCP | 8080 | `0.0.0.0/0` for this demo |

Port 8080 makes the demo reachable over HTTP. For a production website, use a domain, HTTPS, and a reverse proxy instead.

Connect from your computer, replacing the key path and public IP:

```bash
ssh -i /path/to/your-key.pem ubuntu@EC2_PUBLIC_IP
```

## 3. Install tools and clone the repository on EC2

Run these commands in the EC2 terminal:

```bash
sudo apt update
sudo apt install -y git openjdk-17-jdk maven
java -version
mvn -version
```

Clone your repository. Replace the URL with the HTTPS URL for a public repository, or use your configured SSH URL for a private repository:

```bash
cd /home/ubuntu
git clone https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY.git java-devops-demo
cd java-devops-demo
```

Build the runnable JAR:

```bash
mvn clean package
```

## 4. Run the app as a service

Create a systemd service so the app keeps running after you disconnect from SSH and starts again if the server reboots:

```bash
sudo tee /etc/systemd/system/java-devops-demo.service > /dev/null <<'EOF'
[Unit]
Description=Java DevOps Demo
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/java-devops-demo
Environment=PORT=8080
Environment=APP_MESSAGE=Hello from my EC2 server!
ExecStart=/usr/bin/java -jar /home/ubuntu/java-devops-demo/target/java-devops-demo.jar
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now java-devops-demo
```

Check that it is running:

```bash
sudo systemctl status java-devops-demo
curl http://localhost:8080/health
```

Open this address in your browser, replacing the IP with your EC2 public IPv4 address:

```text
http://EC2_PUBLIC_IP:8080/
```

## 5. Deploy later changes

After you commit and push changes from VS Code, connect to EC2 and run:

```bash
cd /home/ubuntu/java-devops-demo
git pull
mvn clean package
sudo systemctl restart java-devops-demo
sudo systemctl status java-devops-demo
```

To see application logs if something goes wrong:

```bash
sudo journalctl -u java-devops-demo -n 100 --no-pager
```

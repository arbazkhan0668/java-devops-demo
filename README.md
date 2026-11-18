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

All server commands in this guide are run inside the EC2 virtual machine using the AWS Console's **EC2 Instance Connect** browser terminal. You do not need to connect from your local computer using SSH or copy files from it.

GitHub Actions only checks that the project builds. It does not connect to EC2 or deploy the app. Deployment and later updates are run from the EC2 instance.

## What you have already done

You said Java, Maven, and the EC2 security-group port are already set up. The examples below use port `8080`. Make sure the port allowed in the EC2 security group is the same as the app's `PORT` value.

## 1. Open a terminal on EC2

In the AWS Console, go to **EC2 → Instances**, select your instance, and choose **Connect → EC2 Instance Connect → Connect**. Run the following commands in that browser terminal.

If you cannot connect with EC2 Instance Connect, check the AWS Console's connection requirements for your instance and region, or use AWS Systems Manager Session Manager if it is configured. Do not use a local SSH/SCP command for this procedure.

## 2. Install Git and clone the GitHub repository

Java and Maven are already installed. Check them and install Git if needed:

```bash
java -version
mvn -version
sudo apt update
sudo apt install -y git
```

Clone your repository. Replace the URL with your repository's HTTPS URL:

```bash
cd /home/ubuntu
git clone https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY.git java-devops-demo
cd /home/ubuntu/java-devops-demo
```

If the repository is private, GitHub will require authentication. Use HTTPS and a GitHub Personal Access Token when Git prompts for credentials; never put the token in the URL or commit it to the repository. A public repository can be cloned without credentials.

If you have already cloned the repository, do not clone it again; open the existing folder instead:

```bash
cd /home/ubuntu/java-devops-demo
```

## 3. Build the application on EC2

From the project directory, run:

```bash
mvn clean package
```

This creates `target/java-devops-demo.jar`.

## 4. Start the app as a service

The project includes a systemd service file configured for the default Ubuntu user, project folder, and port `8080`. Install and start it from the project directory:

```bash
sudo cp deploy/java-demo.service /etc/systemd/system/java-devops-demo.service
sudo systemctl daemon-reload
sudo systemctl enable --now java-devops-demo
```

Check the service and its health endpoint:

```bash
sudo systemctl status java-devops-demo
curl http://localhost:8080/health
```

In a browser, open `http://EC2_PUBLIC_IP:8080/`, replacing `EC2_PUBLIC_IP` with the instance's public IPv4 address. The security group must allow inbound traffic on port `8080`.

If you selected a different port, update the `PORT` setting in `deploy/java-demo.service` and allow that same port in the EC2 security group. Then reload systemd and restart the service:

```bash
sudo systemctl daemon-reload
sudo systemctl restart java-devops-demo
```

## 5. Make and deploy changes from EC2

You can edit files directly on EC2 with a terminal editor such as `nano`. For example:

```bash
cd /home/ubuntu/java-devops-demo
nano src/main/resources/application.properties
```

After changing the code, rebuild and restart the app:

```bash
mvn clean package
sudo systemctl restart java-devops-demo
sudo systemctl status java-devops-demo
```

If you also want to save changes back to GitHub from EC2, configure Git with your name and email, then commit and push over HTTPS:

```bash
git config --global user.name "Your Name"
git config --global user.email "YOUR_EMAIL"
git add .
git commit -m "Update Java demo app"
git push
```

When Git prompts for GitHub credentials, use your GitHub username and a Personal Access Token with repository write access. Do not store the token in project files or in the Git remote URL.

## Troubleshooting

View the application logs:

```bash
sudo journalctl -u java-devops-demo -n 100 --no-pager
```

Check that the application port, systemd `PORT` setting, and EC2 security-group inbound port all match.

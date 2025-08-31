# 1. Deploy and screenshot
pulumi up

# 2. Get outputs and screenshot
pulumi stack output --json

# 3. Manual SSH sessions with screenshots
ssh -i ~/.ssh/id_rsa ops@$(pulumi stack output bastion_public_ip)

# Take screenshot, then exit and run:
ssh -J ops@$(pulumi stack output bastion_public_ip) ubuntu@10.0.2.231 -i ~/.ssh/id_rsa

# 4. On private instance, screenshot these:
sudo systemctl status mysql
mysql -u appuser -p -e "SHOW DATABASES;"

# 5. Test connectivity and screenshot
curl https://aws.amazon.com

# 6. From bastion, test MySQL and screenshot
mysql -h $(pulumi stack output db_server_private_ip) -u appuser -p -e "SELECT 1;"

# 7. Destroy and screenshot
pulumi destroy
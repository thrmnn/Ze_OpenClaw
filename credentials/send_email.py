#!/usr/bin/env python3
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os

# Load credentials
gmail_email = "zeclawd@gmail.com"
gmail_password = "PYmd53ZAeJNEdk"

# Email details
to_email = "alezzandro1.618@gmail.com"
subject = "Hi from Zé"
body = "Hi"

# Create message
msg = MIMEMultipart()
msg['From'] = gmail_email
msg['To'] = to_email
msg['Subject'] = subject
msg.attach(MIMEText(body, 'plain'))

# Send via Gmail SMTP
try:
    with smtplib.SMTP_SSL('smtp.gmail.com', 465) as server:
        server.login(gmail_email, gmail_password)
        server.send_message(msg)
    print("Email sent successfully")
except Exception as e:
    print(f"Error: {e}")

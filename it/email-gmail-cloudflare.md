# Free Unlimited Custom Domain Email Addresses with Gmail and Cloudflare. CodingEntrepreneurs

[Free Unlimited Custom Domain Email Addresses with Gmail and Cloudflare. CodingEntrepreneurs](https://youtu.be/NmXWA08ly_s?si=ZiG-CttQx2GdSkAP)


## Prerequisites

1. **Gmail account** (you’ll forward incoming mail into this).
2. **Custom domain** you own and can point to Cloudflare (register anywhere, then add to Cloudflare).

---

## Step-by-Step Guide

### 1. Add Your Domain to Cloudflare
1. Sign up or log in at **Cloudflare**.
2. Click **Add site**, enter your domain (e.g. `yourdomain.com`), and choose the **Free** plan.
3. Review existing DNS records (if any) and leave them proxied/off as needed.

### 2. Update Name Servers
1. In Cloudflare’s dashboard you’ll see two nameservers (e.g. `abby.ns.cloudflare.com`, `bob.ns.cloudflare.com`).
2. At your registrar (Name.com, GoDaddy, etc.), replace the current NS records with the Cloudflare ones.
3. Wait for propagation (typically 5–15 min, up to a few hours).

### 3. Enable Cloudflare Email Routing
1. In Cloudflare, go to **Email** → **Setup email routing**.
2. Click **Add address**:
   - **Custom address**: e.g. `hello@yourdomain.com`
   - **Destination**: your Gmail (e.g. `yourname@gmail.com`)
3. Click **Create**. Cloudflare sends a verification message to your Gmail.

### 4. Verify Forwarding Address
1. In Gmail, open the Cloudflare verification email and click **Verify**.
2. Back in Cloudflare’s Email Routing tab, ensure your rule shows **Active**.

### 5. Add Required DNS Records
Cloudflare will prompt you to add:
- **MX** records for `yourdomain.com` pointing to Cloudflare’s mail servers.
- A **TXT** record for ownership verification/SPF.
Click **Add records** and confirm they appear in **DNS**.

### 6. Test Incoming Mail
1. From any other account, send a message to `hello@yourdomain.com`.
2. Check that it arrives in your Gmail (may land in Spam—mark **Not spam** if needed).

### 7. Create a Gmail App Password
1. In Gmail, click your profile → **Manage your Google Account** → **Security**.
  - search bar type: "app passwords"
  - app name: my@email.com app password for gmail
3. Copy the 16-character password (you’ll use this instead of your normal password).

### 8. Configure “Send as” in Gmail
1. In Gmail settings → **Accounts and Import** → **Send mail as**, click **Add another email address**.
2. Enter your custom address (`hello@yourdomain.com`) and **treat as an alias**.
3. For SMTP settings:
   - **SMTP Server**: `smtp.gmail.com`
   - **Port**: `587` (TLS)
   - **Username**: your full Gmail address (`yourname@gmail.com`)
   - **Password**: the **App password** you generated
4. Click **Add Account**; Google will send a confirmation to `hello@yourdomain.com`, which will forward to your Gmail—click the confirmation link.

### 9. Test Outbound Mail
1. Compose a new message in Gmail; in the **From** dropdown, select `hello@yourdomain.com`.
2. Send to another address and verify it arrives with your custom domain in the From field.
3. In **Accounts and Import**, set **“When replying to a message”** to **“Reply from the same address the message was sent to.”**

### 10. Create Additional Addresses (Optional)
- Repeat **Step 3** and **Step 4** for any new alias (e.g. `info@`, `support@`, `yourname@`).
- All will forward into the same Gmail inbox and can be configured under **Send mail as**.

---

## Tips & Considerations

- **Use a fresh domain** for fewer DNS conflicts.
- **Enable 2-Step Verification** on your Google account for security.
- **Manage App Passwords**: revoke any you no longer need.
- This setup is a free workaround—if you outgrow it, consider Google Workspace or a dedicated mail provider.




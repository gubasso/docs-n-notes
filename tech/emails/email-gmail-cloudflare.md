# Free Unlimited Custom Domain Email Addresses with Gmail and Cloudflare

*CodingEntrepreneurs*

- [Free Unlimited Custom Domain Email Addresses with Gmail and Cloudflare. CodingEntrepreneurs](https://youtu.be/NmXWA08ly_s?si=ZiG-CttQx2GdSkAP)
- [Cloudflare Email Setup (Free Professional Custom Email Setup) IdeaSpot](https://www.youtube.com/watch?v=nNGcvz1Sc_8)

---

## Prerequisites

Before you begin, make sure you have:

* **BACKUP YOUR LOCAL THUNDERBIRD** before do anything.
* **Gmail account**: Incoming mail will be forwarded here.
* **Custom domain**: You must own and control a domain that you can add to Cloudflare.
* **Enable 2-Step Verification** on your Google account to secure access and allow App Passwords.

## Tips & Considerations

* **Use a fresh domain** to avoid DNS conflicts with existing services.

---

## Receiving Emails

Follow these steps to forward incoming mail for your custom address into your Gmail account.

### Add Your Domain to Cloudflare

1. Sign in (or sign up) at [Cloudflare](https://dash.cloudflare.com/).
2. Click **Add site**, enter your domain (e.g., `yourdomain.com`), and select the **Free** plan.
3. Review existing DNS records. Disable proxying (grey cloud) for any records that should not pass through Cloudflare.

### Update Name Servers at Your Registrar

1. In Cloudflare's dashboard, note the two nameservers (e.g., `abby.ns.cloudflare.com` and `bob.ns.cloudflare.com`).
2. Log in to your domain registrar (e.g., Name.com, GoDaddy).
3. Replace the current NS records with the Cloudflare nameservers.
4. Save changes and wait for DNS propagation (usually 5–15 minutes, but it can take up to 24 hours).

### Enable Cloudflare Email Routing

1. In Cloudflare, navigate to **Email** → **Setup email routing**.
2. Click **Add address**:
   * **Custom address**: e.g., `hello@yourdomain.com`
   * **Destination**: your Gmail address (e.g., `yourname@gmail.com`)
3. Click **Create**. Cloudflare will send a verification message to your Gmail.

### Verify Forwarding Address

1. In Gmail, open the verification email from Cloudflare and click **Verify**.
2. Return to Cloudflare’s Email Routing tab and confirm the rule status is **Active**.

### Add Required DNS Records

1. In Cloudflare, when prompted, add the following records:
   * **MX** records for `yourdomain.com` pointing to Cloudflare’s mail servers.
   * **TXT** record for SPF/ownership verification.
2. Click **Add records** and verify they appear in the **DNS** settings.

### Test Incoming Mail

1. From another email account, send a message to `hello@yourdomain.com`.
2. Confirm it arrives in your Gmail inbox (or Spam—mark as **Not spam** if needed).

---

## Sending Emails

To send from your custom domain, we’ll use Brevo (formerly SendinBlue) as the SMTP relay.

### Domain Setup at Brevo

1. Create or log in to your account at [brevo.com](https://www.brevo.com/).
2. Click your profile icon (top right) and select **Senders, Domains & Dedicated IPs**.
3. Go to the **Domains** tab and click **Add a domain**.
4. Follow the prompts to let Brevo automatically configure DNS in Cloudflare.
5. Wait for DNS propagation and ensure the domain status is **Authenticated**.

### Generate an SMTP Key at Brevo

1. In your Brevo dashboard, click your profile icon and choose **SMTP & API**.
2. Under the **SMTP** tab, click **Generate a new SMTP key**.
3. Copy the SMTP settings and generated key for the next step.

### Configure Gmail to Send as Your Custom Address

1. In Gmail, go to **Settings** → **Accounts and Import**.
2. Under **Send mail as**, click **Add another email address**.
3. Enter your full custom address (e.g., `hello@yourdomain.com`) and keep **Treat as an alias** checked.
4. Click **Next** and enter Brevo’s SMTP settings:
   * **SMTP server**: as provided by Brevo
   * **Port**: as provided by Brevo
   * **Username**: as provided by Brevo login
   * **Password**: the SMTP key you generated
5. Complete the verification steps in the confirmation email sent by Gmail.

### Finalize Settings and Test

1. In Gmail **Settings** → **Accounts and Import**, set your custom address as **Default** for sending.
2. Under **When replying to a message**, choose **Reply from the same address the message was sent to**.
3. Add your custom address to your Google Account as an **Alternative email**:
   * Go to **Manage your Google Account** → **Personal info** → **Contact info** → **Email** → **Alternate emails**.
    - Or search for "Email (personal info)"
   * Add and verify following Google’s prompts.
4. Test your configuration using [Mail-Tester](https://www.mail-tester.com/) to ensure proper delivery and spam score.

# Nginx + certbot

- install certbot

- run certbot (always after add another site/service)
  - https://stackoverflow.com/questions/49172841/how-to-install-certbot-lets-encrypt-without-interaction
  - https://eff-certbot.readthedocs.io/en/stable/using.html
  - --noninteractive / -n
  - --register-unsafely-without-email
    - to substitute email at certificate

```
sudo certbot --nginx -n -m myemail@example.com --agree-tos -d example.com -d www.example.com
sudo certbot --nginx -n --register-unsafely-without-email --agree-tos -d example.com -d www.example.com
```

With interaction (prompt):

```
sudo certbot --nginx
```

- put email
- (A)gree
- give email? no
- which domain? (enter to accept all)
- do you wanna redirect these sites? (http to https, removing http access)... yes

- (when finished, certbot will have changed nginx config files)

- check new `nginx.conf` file
- check if certbot have added:
    ```
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2; #disable SSL
    # check if certbot has added:
        # ciphers directive
        # DH params
        # HSTS adD_header Stric-Transport-Security
        # ssl_session_cache ssl_session_timeout ssl_session_tickets
    ```

- check a renew certificate:

```
sudo certbot renew --dry-run
```

- set a cronjob to renew certificate every 30 days (the certificate lasts for 90 days)
    - `sudo certbot renew`
    ```
    sudo crontab -e
    ---
    30 4 1 * * sudo certbot renew --quiet
    ```

SSL Server Test

https://www.ssllabs.com/ssltest/

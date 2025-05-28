# Wasabi Storage

> object storage, buckets, aws s3


```sh
# Wasabi US West 1 (Oregon)
wasabi_service_url=s3.us-west-1.wasabisys.com
wasabi_bucket_name=<my_bucket_name>
echo "s3:https://$wasabi_service_url/$wasabi_bucket_name"
```

---

- list bucket files with aws cli:

```
# https://wasabi-support.zendesk.com/hc/en-us/articles/360037276392-How-can-I-see-the-size-of-my-buckets-
aws s3 ls --summarize --human-readable --recursive s3://mikeo-test-overwrite1 --endpoint-url=https://s3.wasabisys.com
```

- ursl by region: What are the service URLs for Wasabi's different storage regions?
  - https://wasabi-support.zendesk.com/hc/en-us/articles/360015106031-What-are-the-service-URLs-for-Wasabi-s-different-regions-

- How do I use AWS CLI with Wasabi?
  - https://wasabi-support.zendesk.com/hc/en-us/articles/115001910791-How-do-I-use-AWS-CLI-with-Wasabi-

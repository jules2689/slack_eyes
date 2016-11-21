# bridge_troll

<img src="http://media.giphy.com/media/NMEUUizWg8372/giphy-tumblr.gif" alt="" width="300" />

Bridge Troll is a gateway to assets that need to be distributed securely. In essence, it uses Shopify/signpost to authenticate HTTP requests with SSH keys, and returns timed presigned URLs to download protected assets in a preconfigured S3 bucket.

## Getting Started

Bridge Troll runs via `dev`, and binds to port 9393 by default:

    dev clone bridge_troll
    dev up
    dev server

## Configuration

For local development, you'll need some setup. Create a file named `.development.env` in the root of this project, and set the following properties:

|          Name         |                                     Description                                    |
| :-------------------: | :--------------------------------------------------------------------------------: |
|       AWS_REGION      | Region to use (this really doesn't matter much, so you can default to `us-east-1`) |
|     AWS_S3_BUCKET     |                  This is the bucket where the assets will live in                  |
|   AWS_ACCESS_KEY_ID   |                     This is the AWS access key ID to the bucket                    |
| AWS_SECRET_ACCESS_KEY |                   This is the AWS secret access key to the bucket                  |
|    AUTHME_PASSWORD    |  This is the password for the Authme Heroku app (you can find it in the dashboard) |
|      CACHE_TOKEN      |           This is a token that will authorize the cache busting endpoint           |

The end result looks something like this:

    AWS_REGION="us-east-1"
    AWS_S3_BUCKET="signpost-test"
    AWS_ACCESS_KEY_ID="THE_ACCESS_KEY_ID"
    AWS_SECRET_ACCESS_KEY="THE_SECRET_ACCESS_KEY"
    AUTHME_PASSWORD="THE_PASSWORD_WITH_\$_ESCAPED"
    CACHE_TOKEN="SOME_RANDOM_TOKEN"

Note that you'll need to escape `$` in config values.

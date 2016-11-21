Slack Eyes
---

Slack Eyes is a daemonized ruby script that uses Slack's Real Time Event api to analyze your messages and alert you when you say something that may not be using the best tone.

It uses IBM's Bluemix to analyze the tone of the message and sends a private message back to you if it thinks you could improve your wording.

The messages will be stored in Airtable for future analysis.

![Example Output](https://cloud.githubusercontent.com/assets/3074765/20502590/b8b679e0-b00c-11e6-8520-d22f30f8053a.png)

App Setup
---
- Requires Ruby, Bundler
- Run `bundle install`
- Requries ejson files in config for development and production
  - `config/secrets.production.ejson`
  - `config/secrets.development.ejson`
  - See `config/secrets.test.json` for the entires required

Server Setup
---
- chruby
- ruby 2.3.1
- bundler
- Put EJSON key on the server

Slack Eyes
---

Slack Eyes is a daemonized ruby script that uses Slack's Real Time Event api to analyze your messages and alert you when you say something that may not be using the best tone.

It uses IBM's Bluemix to analyze the tone of the message and sends a private message back to you if it thinks you could improve your wording.

App Setup
---
- Requires Ruby, Bundler
- Run `bundle install`
- Requries the ejson private keys for the secrets, or make your own
 - Slack, Bluemix, Airtable credentials required

Server Setup
---
- chruby
- ruby 2.3.1
- bundler
- Put EJSON key on the server

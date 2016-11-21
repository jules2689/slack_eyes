# slack_eyes

Slack Eyes is a daemonized ruby script that uses Slack's Real Time Event api to analyze your messages and alert you when you say something that may not be using the best tone.

It uses IBM's Bluemix to analyze the tone of the message and sends a private message back to you if it thinks you could improve your wording.

Server Setup
---
- chruby
- ruby 2.3.1
- bundler
- Put EJSON key on the server

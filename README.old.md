# Astra-loom

Loom is a thread based chat server, where users can send messages to one or more threads via hashtags (ex. "I'm heading to the park at noon #family #friends #frisbee_club" ).  Users can subscribe to new threads they see by clicking them and start new threads but just adding a new hashtag to a message.

The demo app demostrates working with DataStax Astra, Elixir, and Phoenix Liveviews together. The project attempts to make the best use of this stack.  Messages histories are saved and loaded in Astra, while new messages are shared via Phoenix channels between all active users in a "thread".  The goal is a fast, scalable, and durable chat/messaging application.

## Requirements

You'll need:
* an Astra database https://astra.datastax.com (Free tier is fine, I recommend the serverless beta for this project)

You might want:
* a google auth developer account
* a gitpod.io account

## Fast Start (gitpod.io)

_NOTE: You can skip any Google auth setup on gitpod.io, setting up Google auth on gitpod is beyond the scope of this document._

Click this link to open a gitpod IDE for the project https://gitpod.io#https://github.com/omnifroodle/astra-loom

You will be prompted for the following:
* "ASTRA_ID" - This is your Astra database ID, you can find this on the Astra web dashboard
* "ASTRA_REGION" - The region where your Astra database is hosted, this is also on the Astra web dashboard
* "ASTRA_USERNAME" - The username for you Astra database
* "ASTRA_PASSWORD" - The password for your Astra username

The webserver should start automatically in a new window or tab of your brower.

Open a terminal and initialize your Astra db schema with the following command:

```bash
mix loom.init
```

Click "Random Dev User" to login with a random identity and look around.

## Docker

See https://hub.docker.com/repository/docker/omnifroodle/astra-loom for information about launching the astra-loom docker container.

## Running localy
Copy `example.env` to `.env` and update it with your Astra and Google credentials.

Run the following to setup your environment:

```bash
source .env
mix deps.get
cd assets && npm install
mix loom.init
```

To start the server

```bash
source .env
mix phx.server
```
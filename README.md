# IdleLoggerAgent

This is a native OSX Agent that will force logout users after 20 minutes of being idle.  Since applications can hold up the logout process, this agent will go through all active applications and force quit them. This could be useful in a public computer lab situation where users walk away and the Mac gets locked.

Both the logout time and a application force quit exclusion list is changeable in the source code only. 

Here is an example on how to deploy this application as an agent in your environment. To use this application as User Agent: 1) Install the application to a directory of your choosing. 2) Create a launch agent plist like detailed here: https://robots.thoughtbot.com/example-writing-a-launch-agent-for-apples-launchd 

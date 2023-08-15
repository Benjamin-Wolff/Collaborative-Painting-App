CS5500-Final Project

## Team

**Team Name**: *Team BYYZ*

Team member Names:
1. Mengxiao Zhao
2. Fan Yang
3. Yaqian Yang
4. Benjamin	Wolff


## Project Description

This is a drawing application that allows multiple clients to draw simutanously online.


## Instruction on how to build the application

- [ ] This is a dub project.

  - Run command "dub run", and the application will start.
  - Run command "dub test" to run all the unit tests.
  - Documentations are in "generated docs" folder, and the main page is index.html


- [ ] The user then needs to type in user commands based on the instructions in the app.

 - Client: If you are a client, type in "c", and follow by a hostname and port. You can choose to connect to local server or aws server.
   - [ ] Connect to AWS server: type in AWS hostname - 3.19.60.89, port- 50002
   - [ ] Connect to local server: type in hostname - "localhost", port - 50002. Then you need to manully open the server locally(see following instructions)


 - Server: The server can be run both locally and on AWS. 
   - [ ] If you want to run the server locally, type in "s", and then follow by hostname-"localhost" and port-"50002".
   - [ ] If you want to run the server on AWS, the AWS server is already deployed and running (nothing to do on your side)


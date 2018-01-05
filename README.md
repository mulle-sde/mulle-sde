🏋🏼 Cross-platform IDE for the C language family 

... for Linux, OS X, FreeBSD, Windows

**mulle-sde** is a commandline based software development environment.
 
* creates projects 
* builds your project via **mulle-craft**
* tests your project via **mulle-test**
* adds and removes dependencies via **mulle-sourcetree** (+ cmake support)
* monitors filesystem changes and update your project files (+ cmake support)

You will likely use **mulle-sde** inside **mulle-env**, so that 
environment variables are properly set up.


Executable      | Description
----------------|--------------------------------
`mulle-sde`     | Create projects, add and remove dependencies, monitor filesystem and rebuild and test on demand 


## Create a **mulle-sde** "hello world" project

A **mulle-sde** project is a (currently) a **cmake** project. Since the 
various tools are configured with environment variables, it makes sense 
to setup a virtual environment using **mulle-env**, so that various projects
can coexist.

```
mulle-env init hello
```

Enter the environment:

```
mulle-env hello
```

Create a tool cmake project for C:

```
mulle-sde init executable
``` 

Build it:

```
mulle-craft
``` 

## mulle-sde dependency

![](mulle-sde-dependency.png)


## mulle-sde monitor

![](mulle-sde-monitor.png)

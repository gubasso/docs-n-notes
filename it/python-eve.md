# Python-Eve

- objective: build bullets for server course/training

- for written product: write a complete step-by-step, objective, as much bullet points as possible
    - with the extra steps (flask introduction, etc)

- tools
    - test api: https://hoppscotch.io/

## steps to setup server
> last section of tutorial: sumup of steps to setup server and run in production, use real script and code

- python organize files and directories

- gunicorn docs and options, check maia's course

- install python (use asdf, latest version)
- set poetry
[^flask_intro]
- install pdm `eve`
[^eve]
- install `gunicorn`
    - exposed through nginx
    - force to be used just to a user?
- install mongodb
    - arch wiki / official docs
    - separated config file to run
    - just localhost: `bindIp: 127.0.0.1`
    - only python gunicorn is exposed through nginx
    - use ufw firewall to ensure security steps
        - ufw default deny incoming
        - ufw default allow outgoing
        - ufw allow ssh... etc...
        - ufw enable
[^why_mongo]
- rate limit: let it to nginx, Cade's TI will handle it
- cache optimization
    - python-eve docs
- setup python service (gunicorn?)

## extra steps just for tutorial

- [^flask_intro]
    - Introducing Flask [ch4/11]: Hello world, Flask-style [v2/2]
    - what is a python decorator `@`

- [^eve]
    - show root endpoint, where shows all domains (rest endpoints)
    - What is Eve? [ch5/11]: Exploring Eve: Getting Started [v2/5]
        - basic calls to see just the results
        - python-eve.org live demo? use it as a eve introduction?
            - test api results and see return from eve-demo-herokuapp
        - Fine-tuning your REST service [ch10/11]: HATEOAS [v6/13]
            - if not used, can be desabled for optimization
    - What is Eve? [ch5/11]: Exploring Eve: Queries [v3/5]
    - What is Eve? [ch5/11]: Exploring Eve: Sorting [v4/5]
    - What is Eve? [ch5/11]: Exploring Eve: Pagination [v5/5]
    - hands-on: create basic eve server
        - use step by step from the course, but apply to real case in cadelab
        - Your first Eve service [ch7/11]: Let's build and launch our first app [v1/6]
        - Your first Eve service [ch7/11]:
            - Let's build and launch our first app [v1/6]
            - Connecting to Mongo [v2/6]
            - Enabling writes [v3/6]
                - for cadelab is just read operations
            - Defining document schemas [v4/6]
                - Schema definitions and validation [ch9/11]: Introduction to data validation [v1/6]
                - Schema definitions and validation [ch9/11]: Built-in validation rules [v2/6]
            - Fine-tuning your REST service [ch10/11]: Still a Flask app [v11/13]
            - Schema definitions and validation [ch9/11]: Data-relations and embedded resource serialization [v4/6]
            - !! (focus on only writes... just introduce all the options, as only the get method will be used for cadelab) Full range of CRUD operations [v5/6]
            - Recap [v6/6]
                - specifc config for each endpoint (data collection)
        - Fine-tuning your REST service [ch10/11]: Query options and security [v2/13]
        - Fine-tuning your REST service [ch10/11]: Pagination options and performance optimizations [v3/13]
        - Fine-tuning your REST service [ch10/11]: Client and server projections [v4/13]
        - Fine-tuning your REST service [ch10/11]: JSON and XML rendering [v7/13]
        - Fine-tuning your REST service [ch10/11]: Event hooks [v9/13]
        - Fine-tuning your REST service [ch10/11]: Rate limiting [v10/13]
            - redis set rate limit
    - eve applied to specifc cases in cadelab
        - Fine-tuning your REST service [ch10/11]: A small refactoring [v13/13]
            - directory structures, project organization
        - test with cadelab api running too
        - call api from js in the page
            - simulate a button
            - if has CORS issue: `X_DOMAINS = '*'` or `X_DOMAINS = ['exemple.com', 'mysite.org']`
            

- [^why_mongo]
    - Why MongoDB? [ch6/11]: Why Mongo is a good match for REST [v1/1]
        - translate course

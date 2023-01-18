# Python Flask

cache implementation: https://explore-flask.readthedocs.io/en/latest/views.html#caching

[How to import function into main file in flask?](https://stackoverflow.com/questions/54090720/how-to-import-function-into-main-file-in-flask)

# General

- http://www.compjour.org/lessons/flask-single-page/multiple-dynamic-routes-in-flask/

## return a json

From a Mongo (pymongo) Curse:

```
from flask import Response, request
from bson.json_util import dumps

mongo_curse = mongo.db.my_collection.find({"mykey": myvalue})
mongo_curse = mongo.db.tab0042.find()
# curse to python list
list_cur = list(mongo_curse)
# python list to json_data
json_data = dumps(list_cur)
# respose as json data
return Response(json_data, mimetype='application/json')
```

## query string

Access query string from flask:[^1][^2]

```
# url?A=123&A=456&B=789.
args = request.args
qstr = args.lists() # A generator for the multi-dict

# [('A',['123','456']),('B',['789'])]

qstr = list(qstr) # multi-dict to python list
json_data = dumps(qstr) # list to json

qstr = args.getlist("b") # return a python list from a valid multi-dict key
json_data = dumps(qstr) # python list to json

# dictionary where the first occurrence of a duplicate keyword is used
qstr = request.args.to_dict() # just {'A': 123, 'B': 789}

return Response(json_data, mimetype='application/json')
```

## References:

[^1]: [How do you access the query string in Flask routes?](https://stackoverflow.com/questions/11774265/how-do-you-access-the-query-string-in-flask-routes/69998227#69998227)
[^2]: [Getting the array as GET query parameters in Python](https://stackoverflow.com/questions/7940085/getting-the-array-as-get-query-parameters-in-python/7940355#7940355)

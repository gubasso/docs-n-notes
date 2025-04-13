# Python Mongodb

Working with python and mongodb simple example (using pymongo):

```
import pymongo
import pandas as pd

# Conexao MongoDB
client = pymongo.MongoClient("mongodb://localhost:27017/")

client.drop_database('sample')

sample_db = client.sample
randomusers_col = sample_db.randomusers

df = pd.read_csv('./data/randomusers.csv')
list = df.to_dict('records')

randomusers_col.insert_many(list)
```


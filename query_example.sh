curl --request POST \
  --url http://localhost:3000/contract \
  --header 'content-type: application/json' \
  --data '{"contract": "myContract","method": "UpdatePrice","at": "0xb7fb021d3e1a4b55efd3ceb1d6df8c0eea4ae1ba","args": [500]}'
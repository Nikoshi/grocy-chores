Class {
    #name : 'GrocyChoreClient',
    #superclass : 'Object',
    #instVars : [
        'baseUrl',
        'apiKey',
        'httpClient'
    ],
    #classVars : [
        'DefaultApiKey'
    ],
    #category : 'Grocy-Client-Base',
    #package : 'Grocy-Client',
    #tag : 'Base'
}

{ #category : 'accessing' }
GrocyChoreClient class >> defaultApiKey [
    ^ DefaultApiKey
]

{ #category : 'accessing' }
GrocyChoreClient class >> defaultApiKey: aString [
    DefaultApiKey := aString
]

{ #category : 'accessing' }
GrocyChoreClient >> apiKey: aString [
    apiKey := aString.
    httpClient ifNotNil: [ 
        httpClient headerAt: 'grocy-api-key' put: apiKey ]
]

{ #category : 'accessing' }
GrocyChoreClient >> baseUrl [
    ^ baseUrl
]

{ #category : 'accessing' }
GrocyChoreClient >> baseUrl: aString [
    baseUrl := aString
]

{ #category : 'private' }
GrocyChoreClient >> buildProductCache [

    | productsJson cache |
    productsJson := STONJSON fromString: (httpClient
        url: (self baseUrl , '/objects/products');
        get).

    cache := Dictionary new.
    productsJson do: [ :prod |
        cache at: (prod at: 'id') put: (prod at: 'name') ].
    ^ cache
]

{ #category : 'api - actions' }
GrocyChoreClient >> clearShoppingList [

    | aktuelleListe |
    aktuelleListe := self getShoppingList.
    aktuelleListe do: [ :item | self removeShoppingItemId: item id ]
]

{ #category : 'api - actions' }
GrocyChoreClient >> completeTaskId: anInteger [

    | targetUrl isoDateString jsonBody jsonEntity |
    apiKey ifNil: [ self error: 'Missing API Key' ].
    targetUrl := self baseUrl, '/tasks/', anInteger asString, '/complete'.

    isoDateString := Date today yyyymmdd.
    jsonBody := '{"done_time": "', isoDateString, '"}'.

    jsonEntity := ZnEntity text: jsonBody.
    jsonEntity contentType: ZnMimeType applicationJson.

    httpClient
        url: targetUrl;
        entity: jsonEntity;
        post.

    httpClient isSuccess ifFalse: [
        self error: 'Grocy API Fehler: ', httpClient response statusLine asString ]
]

{ #category : 'api - actions' }
GrocyChoreClient >> executeChoreId: anInteger [

    self
        postToChoreId: anInteger
        action: 'execute'
        jsonBody: '{"skipped": false, "done_by": null}'
]

{ #category : 'api - accessing' }
GrocyChoreClient >> getChores [

    | jsonArray |
    apiKey ifNil: [ self error: 'Missing API Key' ].

    jsonArray := STONJSON fromString: (httpClient
        url: (self baseUrl, '/chores');
        get).

    ^ jsonArray collect: [ :each |
        GrocyChore new
            id: (each at: 'chore_id')
            name: (each at: 'chore_name')
            nextExecution: (each at: 'next_estimated_execution_time') ]
]

{ #category : 'api - accessing' }
GrocyChoreClient >> getShoppingList [

    | shoppingJson productCache |
    apiKey ifNil: [ self error: 'Missing API Key' ].

    productCache := self buildProductCache.

    shoppingJson := STONJSON fromString: (httpClient
        url: (self baseUrl , '/objects/shopping_list');
        get).

    ^ shoppingJson collect: [ :each |
        self mapShoppingItem: each withCache: productCache ]
]

{ #category : 'api - accessing' }
GrocyChoreClient >> getTasks [

    | jsonArray |
    apiKey ifNil: [ self error: 'Missing API Key' ].

    jsonArray := STONJSON fromString: (httpClient
        url: (self baseUrl, '/tasks?status=open');
        get).

    ^ jsonArray collect: [ :each |
        GrocyTask new
            id: (each at: 'id')
            name: (each at: 'name')
            dueDate: (each at: 'due_date') ]
]

{ #category : 'initialization' }
GrocyChoreClient >> initialize [
    super initialize.
    baseUrl := 'http://localhost:9283/api'.
    httpClient := ZnClient new.
    self class defaultApiKey ifNotNil: [ :key | self apiKey: key ]
]

{ #category : 'private' }
GrocyChoreClient >> mapShoppingItem: each withCache: productCache [

    | itemId prodId prodName noteText itemAmount |
    itemId := each at: 'id'.
    itemAmount := each at: 'amount' ifAbsent: [ 1 ].
    noteText := each at: 'note' ifAbsent: [ nil ].

    prodId := each at: 'product_id' ifAbsent: [ nil ].
    prodName := prodId
        ifNil: [ nil ]
        ifNotNil: [ productCache at: prodId ifAbsent: [ 'Unbekanntes Produkt' ] ].

    ^ GrocyShoppingItem new
        id: itemId
        productName: prodName
        amount: itemAmount
        note: noteText
]

{ #category : 'private' }
GrocyChoreClient >> postToChoreId: anInteger action: actionString jsonBody: jsonString [

    | targetUrl jsonEntity |
    apiKey ifNil: [ self error: 'Missing API Key' ].

    targetUrl := self baseUrl, '/chores/', anInteger asString, '/', actionString.

    jsonEntity := ZnEntity text: jsonString.
    jsonEntity contentType: ZnMimeType applicationJson.

    httpClient
        url: targetUrl;
        entity: jsonEntity;
        post.

    httpClient isSuccess ifFalse: [
        self error: 'Grocy API Fehler: ', httpClient response statusLine asString ]
]

{ #category : 'api - actions' }
GrocyChoreClient >> removeShoppingItemId: anInteger [

    | targetUrl |
    apiKey ifNil: [ self error: 'Missing API Key' ].
    
    targetUrl := self baseUrl, '/objects/shopping_list/', anInteger asString.

    httpClient
        url: targetUrl;
        delete
]

{ #category : 'api - actions' }
GrocyChoreClient >> skipChoreId: anInteger [

    self
        postToChoreId: anInteger
        action: 'execute'
        jsonBody: '{"skipped": true, "done_by": null}'
]

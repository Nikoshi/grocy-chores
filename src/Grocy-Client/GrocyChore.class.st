"
Simple serialized version of a chore
"
Class {
	#name : 'GrocyChore',
	#superclass : 'Object',
	#instVars : [
		'id',
		'name',
		'nextExecution'
	],
	#category : 'Grocy-Client-Base',
	#package : 'Grocy-Client',
	#tag : 'Base'
}

{ #category : 'accessing' }
GrocyChore >> daysRemaining [

	| targetDate |
	nextExecution ifNil: [ ^ 999 ].
	nextExecution size < 10 ifTrue: [ ^ 999 ].

	targetDate := (nextExecution copyFrom: 1 to: 10) asDate.

	^ targetDate subtractDate: Date today
]

{ #category : 'accessing' }
GrocyChore >> id [
	^ id
]

{ #category : 'accessing' }
GrocyChore >> id: anInteger name: aString nextExecution: aDateTimeString [
	id := anInteger.
	name := aString.
	nextExecution := aDateTimeString
]

{ #category : 'accessing' }
GrocyChore >> name [
	^ name
]

{ #category : 'accessing' }
GrocyChore >> nextExecution [
	^ nextExecution
]

{ #category : 'printing' }
GrocyChore >> printOn: aStream [

	| paddedName template |
	paddedName := name padRightTo: 20.
	template := '{1}. {2}: {3}'.
	aStream nextPutAll: (template format: { id . paddedName . nextExecution })
]

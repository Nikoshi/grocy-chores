Class {
	#name : 'BaselineOfGrocyClient',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfGrocyClient',
	#package : 'BaselineOfGrocyClient'
}

{ #category : 'baselines' }
BaselineOfGrocyClient >> baseline: spec [
	<baseline>

	spec for: #common do: [
		"Hier definieren wir dein Hauptpaket"
		spec package: 'Grocy-Client' ]
]

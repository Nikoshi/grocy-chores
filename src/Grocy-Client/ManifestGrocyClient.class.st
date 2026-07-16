"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : 'ManifestGrocyClient',
	#superclass : 'PackageManifest',
	#category : 'Grocy-Client-Manifest',
	#package : 'Grocy-Client',
	#tag : 'Manifest'
}

{ #category : 'code-critics' }
ManifestGrocyClient class >> ruleLongMethodsRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#GrocyChoreBrowser #initializePresenters #false)) #'2026-07-16T20:09:20.212+02:00') )
]

{ #category : 'code-critics' }
ManifestGrocyClient class >> ruleTempsReadBeforeWrittenRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#GrocyChoreBrowser #initializePresenters #false)) #'2026-07-16T20:09:17.649+02:00') )
]

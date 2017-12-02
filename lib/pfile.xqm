xquery version "3.0" encoding "UTF-8";
module namespace pfile = "http://keeleleek.ee/pextract/pfile";
declare namespace pextract = "http://keeleleek.ee/pextract";
import module namespace functx = 'http://www.functx.com';

(:~ 
 : Collection of functions for handling paradigm extract files.
 : 
 : @author Kristian Kankainen, MTÜ Keeleleek
 : @version 0.1
 :)



(:~ Returns the attested variable value sets of given paradigm :)
declare function pfile:get-attested-var-values(
  $paradigm as element(pextract:paradigm)
){
  $paradigm/pextract:variable-values
};



(:~ Returns the attested variable values of the given paradigm as a map. :)
declare function pfile:get-attested-var-values-map(
  $paradigm as element(pextract:paradigm)
){
  (: @todo: create map as map {$num : $value } :)
  let $attested-var-values-map := map:merge(
    for $variable in pfile:get-attested-var-values($paradigm)/pextract:variable-set/pextract:variable
      let $num := xs:integer($variable/pextract:variable-number/data())
      let $val := $variable/pextract:variable-value/string()
      return
        map:entry($num, $val)
  )
  return $attested-var-values-map
};



(:~ Returns a list of recreated word-forms of given paradigm cell :)
declare function pfile:get-attested-wordforms(
  $cell as element(pextract:paradigm-cell),
  $attested-values as element(pextract:variable-values)
) as xs:string+ {
  let $pattern := $cell/pextract:pattern
  let $wordform-list :=
    for $attested-value-set in $attested-values/pextract:variable-set
      let $wordform-parts := 
        for $part in $pattern/pextract:pattern-part
          return
            if (matches($part, "\d+"))
            then ($attested-value-set/pextract:variable[./pextract:variable-number = $part]/pextract:variable-value)
            else ($part)
        
        return string-join($wordform-parts)
      return $wordform-list
};



(:~ Returns all morpho-syntactic descriptors of a given paradigm as a map :)
declare function pfile:get-paradigm-msd-map(
  $paradigm as element(pextract:paradigm)
)
{
  let $msds := $paradigm//pextract:msd-description
  let $msd-map := map:merge(
    let $keys := distinct-values($msds/pextract:feature/pextract:name)
    for $key in $keys
      let $values := distinct-values($msds/pextract:feature[./pextract:name = $key]/pextract:value)
      return map:entry($key, $values)
  )
  return $msd-map
};



(:~ Returns all morpho-syntactic descriptors of a given cell as a map :)
declare function pfile:get-cell-msd-map(
  $cell as element(pextract:paradigm-cell)
)
{
  let $msds := $cell/pextract:msd-description
  let $msd-map := map:merge(
    let $keys := distinct-values($msds/pextract:feature/pextract:name)
    for $key in $keys
      let $values := distinct-values($msds/pextract:feature[./pextract:name = $key]/pextract:value)
      return map:entry($key, $values)
  )
  return $msd-map
};




(:~ Returns all inherent morpho-syntactic descriptors of a given cell as a map :)
(: @todo: fill this place-holder :)
declare function pfile:get-inherent-type-msd-map(
  $cell as element(pextract:paradigm-cell),
  $type-system
)
{
  
};
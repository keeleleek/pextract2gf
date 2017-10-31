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
) {
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


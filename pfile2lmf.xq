xquery version "3.1";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
import module namespace functx = 'http://www.functx.com';
import module namespace pfile = 'http://keeleleek.ee/pextract/pfile' at 'lib/pfile.xqm';
declare namespace pextract = "http://keeleleek.ee/pextract";
declare namespace lmf = "lmf";


(:~
 Simple example for transforming a pfile to LMF Paradigm Patterns
 @author Kristian Kankainen
 @copyright MTÜ Keeleleek 2017
 :)


let $lang-code := "vot"
let $part-of-speech := "noun"
let $example := doc("examples/vot_" || $part-of-speech || ".tdml")

return
  <Lexicon lang="{$lang-code}">
  {
    for $paradigm in $example/pextract:paradigm-file/pextract:paradigm
      return pfile:paradigm-as-lmf-pattern($paradigm, $part-of-speech)
  }
  </Lexicon>
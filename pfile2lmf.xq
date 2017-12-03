xquery version "3.1";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
import module namespace functx = 'http://www.functx.com';
import module namespace pfile = 'http://keeleleek.ee/pextract/pfile' at 'lib/pfile.xqm';
declare namespace pextract = "http://keeleleek.ee/pextract";
declare namespace lmf = "lmf";


(:~
 Simple translator from pfile xml to LMF Paradigm Patterns
 @author Kristian Kankainen
 @copyright MTÜ Keeleleek 2017
 :)


declare function pextract:paradigm-as-lmf-pattern(
  $paradigm as element(pextract:paradigm),
  $part-of-speech as xs:string
) as element(ParadigmPattern)
{
  let $paradigm-lemma := pfile:get-attested-wordforms(
    ($paradigm//pextract:paradigm-cell)[1], (: @todo remove hardcoded selector :)
    pfile:get-attested-var-values($paradigm)
  )[1]
  let $paradigm-id := "as" || functx:capitalize-first($paradigm-lemma)
  let $paradigm-comment := concat('inflectional paradigm pattern for ', $paradigm-lemma)
  return 
  <ParadigmPattern>
    <feat att="id" val="{$paradigm-id}" />
    <feat att="comment" val="{$paradigm-comment}" />
    <feat att="example" val="{$paradigm-lemma}" />
    <feat att="partOfSpeech" val="{$part-of-speech}" />
    {
      for $cell in $paradigm//pextract:paradigm-cell
        let $msd-feats := pfile:get-cell-msd-map($cell)
        return
          <TransformSet>
            <GrammaticalFeatures>
              {
                map:for-each(
                  $msd-feats,
                  function ($key, $value) {<feat att="{$key}" val="{$value}" />} )
              }
            </GrammaticalFeatures>
            {
              for $pattern-part in $cell//pextract:pattern/pextract:pattern-part
                return
                  <Process>
                  {
                    if(matches($pattern-part, "\d+"))
                    then(
                      (: the case it is a variable number :)
                      <feat att="operator" val="addAfter" />,
                      <feat att="variableNumber" val="{$pattern-part}" />
                    )
                    else(
                      (: the case it is a constant string :)
                      <feat att="operator" val="addAfter" />,
                      <feat att="stringValue" val="{$pattern-part}" />
                    )
                  }
                </Process>
            }
          </TransformSet>
    }
  </ParadigmPattern>
};


let $lang-code := "vot"
let $part-of-speech := "noun"
let $example := doc("examples/vot_" || $part-of-speech || ".tdml")

for $paradigm in $example/pextract:paradigm-file/pextract:paradigm
  return pextract:paradigm-as-lmf-pattern($paradigm, $part-of-speech)
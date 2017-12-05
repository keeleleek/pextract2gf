xquery version "3.1";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
import module namespace functx = 'http://www.functx.com';
import module namespace pfile = 'http://keeleleek.ee/pextract/pfile' at 'pextract-xml/lib/pfile.xqm';
declare namespace p = "http://keeleleek.ee/pextract";


(:~ 
 : This converts an extracted paradigms file into Grammatical Framework code.
 : 
 : @author Kristian Keeleleek
 : @version 1.0.0
 : @see https://github.com/keeleleek/pextract2gf
 :)



(:~ Serialize the $params-map as a GF param statement
 : @since 1.0.0
 :)
declare function p:serialize-params ($params-map) as xs:string {
  string-join(
      ("param",
          for $feature in map:keys($params-map)
            let $values := string-join(
                                          for $value in $params-map?($feature)
                                             return if ($translate?($value)) then ($translate?($value)) else ($value),
                                    " | ")
            return concat(
              "  ", if($translate?($feature)) then($translate?($feature)) else ($feature), " = ", $values, " ;")
      )
    , out:nl()
  )
};



(:~ Simple translation map for stuff like 'singular' = 'Sg'
 : @since 1.0.0
 :)
declare variable $translate := map {
  "singular" : "Sg",
  "plural"     : "Pl",
  "grammaticalNumber" : "Number",
  "grammaticalCase"      : "Case"
};



(:~ Serialize the paradigm patterns as GF operations
 : @since 1.0.0
 :)
declare function p:serialize-opers ($pattern-map) as xs:string {
  let $pfile := doc("examples/vot_noun.tdml") (: @todo: remove hardcoded file name :)
  
  return
  string-join(
    ("oper" || out:nl(),
    string-join(
      for $paradigm in ($pfile//p:paradigm)
        let $distinct-variables := distinct-values($paradigm//p:pattern-part[matches(., "\d+")])
        let $num-of-variables := count($distinct-variables)
        let $first-attested-variables-map := pfile:get-attested-var-values-map($paradigm)
        let $constants := ($paradigm//p:pattern-part[matches(., "\D+")])
        let $lemma := pfile:get-attested-wordforms(
                                  ($paradigm//p:paradigm-cell)[1], (: @todo remove hardcoded selector :)
                                  $paradigm//p:variable-values
                                )[1]
        
        (: generate GF table with each paradigm-cell element :)
        let $GF-wordform-table :=
          concat(
            (: generate code for the abstract paradigm function that acts on a lemma :)
            concat(
              (: pattern match lemma as input for the concrete paradigm function :)
              (:
                  mkTüttö : Str -> Noun = \tüttö ->
                    case tüttö of {
                      tüt + "t" + ö => mkTüttöConcrete tüt ö
                      _ => Predef.error "Given lemma doesn't pattern match this paradigm function >:("
                    }
              :)
              "  mk" || functx:capitalize-first(
                              $lemma
                        ) || " : Str -> Noun = \"  || $lemma,
                        " -> " || out:nl(),
                        "    case " || $lemma,
                        " of {" || out:nl(),
                        (: placeholder for tüt + "t" + ö => mkTüttöConcrete tüt ö :)
                        "      ",
                        string-join(
                            let $paradigm-pattern := ($paradigm//p:paradigm-cell)[1]
                            let $last := count($paradigm-pattern//p:pattern/p:pattern-part/data())
                            for $pattern-part at $position in $paradigm-pattern//p:pattern/p:pattern-part/data()
                              return 
                                (: treat the last variable differently :)
                                if ($position ne $last)
                                then (
                                  (: if non-number then constant else get attestation for variable num :)
                                  if (matches($pattern-part, "\D+"))
                                  then(string('"' || $pattern-part || '"'))
                                  else(string($first-attested-variables-map?(xs:integer($pattern-part))[1]))
                                )
                                else (
                                  (: if non-number then constant else get attestation for variable num :)
                                  if (matches($pattern-part, "\D+"))
                                  then(string('"' || $pattern-part || '"'))
                                  else(
                                    (: pattern for making last constant match greedily i.e match the last occurrence :)
                                    let $last-attested-variable := $paradigm-pattern//p:pattern/p:pattern-part[last() - 1]
                                    return
                                      string($first-attested-variables-map?(xs:integer($pattern-part))[1])
                                      || "@" || '(-(_+"' || $last-attested-variable || '"+_))'
                                  )
                                )
                            , " + "
                        ) || " => " || "mk" || functx:capitalize-first(
                                                             $lemma || "Concrete "
                        ),
                        string-join(
                            let $paradigm-pattern := ($paradigm//p:paradigm-cell)[1]
                            for $pattern-part in $paradigm-pattern//p:pattern/p:pattern-part/data()
                              return 
                                if (matches($pattern-part, "\D+"))
                                then()
                                else(string($first-attested-variables-map?(xs:integer($pattern-part))[1]))
                            , " "
                        )
                        , " ; " || out:nl(),
                        (: useful error message :)
                        '      _ => Predef.error "Unsuitable lemma for ',
                        "mk" || functx:capitalize-first(
                              $lemma
                        ) || '"',
                        out:nl(),
                        "    } ;" || out:nl() || out:nl()
            ),
            
            (: generate code for the concrete paradigm-function :)
            concat("  mk",
                        functx:capitalize-first(
                              $lemma || "Concrete"
                        ),
                        " : ",
                        (: string-join("Str", " -> ") for $num-of-variables :)
                        string-join(for $i in 1 to $num-of-variables return "Str", " -> "),
                        " -> Noun = ", (: @todo remove hardcoded POS :)
                        "\", (: the lambda definition :) 
                        (: tü,tö :)
                        string-join(for $variable in $distinct-variables
                                          return $first-attested-variables-map?(xs:integer($variable))[1], ","),
                        " -> ",
                        out:nl())
            
            (: record with inflection table :)
            ,"    { s = ", out:nl(),
            "      table {", out:nl(),
            (: for loop that constructs the content of the table:)
            string-join( for $paradigm-pattern in $paradigm//p:paradigm-cell
              return
                concat(
                  (: @todo we could insert the wordform as documentation here but it seems unnecessary
                  "        -- " || p:reconstruct-wordform($paradigm-pattern, $paradigm//p:variable-values) || out:nl(), :)
                  (: msd-description serialized as NF Pl genitive => :)
                  "        NF ",
                  string-join(
                     for $pattern-msd-feature in $paradigm-pattern//p:msd-description/p:feature
                       let $feature := $pattern-msd-feature/p:value
                       return (
                         (: @todo use translate map for singual=Sg etc :)
                         if (matches($feature, "singular|plural"))
                         then ($translate?($feature))
                         else ($feature)
                       )
                       ," "),
                  " => ",
                  (: poi + "ki" | poi + "kije" :) (: @todo generalize for variants! :)
                  string-join(
                    for $pattern-part in $paradigm-pattern//p:pattern/p:pattern-part/data()
                      return 
                        if (matches($pattern-part, "\D+"))
                        then(string('"' || $pattern-part || '"'))
                        else(string($first-attested-variables-map?(xs:integer($pattern-part))[1]))
                    , " + ")
                )
            , " ; " || out:nl() ) (: end of table content string-join :)
            , out:nl()
            , "      }", out:nl()
            , "    } ;", out:nl()
          )
        
        return $GF-wordform-table
        
    || out:nl() || out:nl() || "-------------------------" || out:nl() || out:nl())
    )
    , out:nl()
  )
};




let $pos := "noun"
let $pfile := doc(concat("examples/vot_", $pos, ".tdml"))

(: Generate the map of GF parameter types :)
(: Collect a map of parameter feature names and values from the pextract file :)
let $param-labels := distinct-values($pfile//p:msd-description/p:feature/p:name/string())
let $params-map := map:merge(
    for $feature-label in $param-labels
      return map:entry(
        string($feature-label), 
        (distinct-values($pfile//p:msd-description/p:feature[./p:name = $feature-label]/p:value/string()))
      )
)

let $paradigm-pattern := "todo" (: @todo: remove this :)

return concat(
  p:serialize-params($params-map), out:nl(), out:nl(),
  p:serialize-opers($paradigm-pattern) (: @todo: pass pfile here :)
)
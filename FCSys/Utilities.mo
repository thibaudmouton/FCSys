within FCSys;
package Utilities "Functions to implement misc. algorithms"
  extends Modelica.Icons.Package;
  package Chemistry "Functions to support chemistry"
    extends Modelica.Icons.Package;
    function charge "Return the charge of a species given its chemical formula"
      extends Modelica.Icons.Function;
      input String formula "Chemical formula";
      output Integer z "Charge number";
    external"C";
      annotation (
        IncludeDirectory="modelica://FCSys/Resources/Source/C",
        Include="#include \"Chemistry.c\"",
        Documentation(info="<html><p>This function returns the net
  electrical charge associated with a species represented by a chemical
  formula (<code>formula</code>).  If the charge number is
  not given explicitly in the formula, then it is assumed to be zero.  A \"+\" or \"-\" without any immediately following digits is interpreted as
  a charge of +1 or -1, respectively.  If there is an error in the chemical formula,
  then 0 is returned.</p>

  <p><b>Example:</b><br>
  <code>charge(\"Hg2+2\")</code> returns 2.</p>
  </html>"));
      // Note:  Since Dymola 7.4 doesn't support the IncludeDirectory annotation,
      // it will be necessary to use the full
      // path in the Include annotation, e.g.
      //   Include="#include \"FCSys/FCSys 2.0/Resources/Source/C/Chemistry.c\""

    end charge;

    function countElements
      "Return the number of elements in a chemical formula"
      extends Modelica.Icons.Function;
      input String formula "Chemical formula";
      output Integer n "Number of elements";
    external"C";
      annotation (
        IncludeDirectory="modelica://FCSys/Resources/Source/C",
        Include="#include \"Chemistry.c\"",
        Documentation(info="<html><p>This function returns the number of elements
      in a chemical formula.  Electrons are counted as a present element (or rather particle)
      if the net charge is nonzero.</p>

   <p><b>Examples:</b><br>
    <code>countElements(\"C19HF37O5S-\")</code> returns 5 and <code>countElements(\"H+\")</code> returns 2.</p>

  <p>Please see the
  <a href=\"modelica://FCSys.Utilities.Chemistry.readElement\">readElement</a> function
  for details about the format of the chemical formula.</p></html>"));
      // Note:  Since Dymola 7.4 doesn't support the IncludeDirectory annotation,
      // it will be necessary to use the full
      // path in the Include annotation, e.g.
      //   Include="#include \"FCSys/FCSys 2.0/Resources/Source/C/Chemistry.c\""

    end countElements;

    function readElement
      "Return the symbol, coefficient, and charge of an element in a chemical formula"
      extends Modelica.Icons.Function;
      input String formula "Chemical formula";
      output String symbol "Name of element (empty if error)";
      output Integer n "Stoichiometric coefficient";
      output Integer z "Charge number";
      output String remainder "Remainder of the chemical formula";
    external"C" readElement(
            formula,
            symbol,
            n,
            z,
            remainder);
      annotation (
        IncludeDirectory="modelica://FCSys/Resources/Source/C",
        Include="#include \"Chemistry.c\"",
        Documentation(info="<html><p>This function returns the symbol (<code>symbol</code>),
  stoichiometric coefficient (<i>n</i>), and
  electrical charge (<i>z</i>) associated with an element as it appears in a chemical
  formula (<code>formula</code>).  After any initial whitespace in the <code>formula</code> string,
  which is ignored, the symbol must begin with a letter and may continue with lowercase letters.
  The symbol may be
  followed by a positive integer and then a charge number (both independently optional).
  If present, the charge number must begin with \"+\" or \"-\" and may be followed by optional digits.
  The <code>remainder</code> output gives the remainder of the <code>formula</code> string after the symbol,
  coefficient, and charge have been extracted.</p>

  <p>If the coefficient is not explicitly given, then it is assumed to be one.  If the charge number is
  not given, then it is assumed to be zero.  A \"+\" or \"-\" without following digits is interpreted as
  a charge of +1 or -1, respectively.  If there is an error,
  then <code>symbol</code> will be an empty string.</p>

  <p><b>Example:</b><br>
  <code>(symbol, n, z, remainder) = readElement(\"Hg2+2\")</code> returns
  <code>symbol=\"Hg\"</code>, <code>n=2</code>, <code>z=2</code>, and <code>remainder=\"\"</code>.</p>
  </html>"));
      // Note:  Since Dymola 7.4 doesn't support the IncludeDirectory annotation,
      // it will be necessary to use the full
      // path in the Include annotation, e.g.
      //   Include="#include \"FCSys/FCSys 2.0/Resources/Source/C/Chemistry.c\""

    end readElement;

    function readSpecies
      "Return the symbols and coefficients of the elements in a chemical formula"
      extends Modelica.Icons.Function;
      input String formula "Chemical formula";
      output String symbols[countElements(formula)] "Symbols of the elements";
      output Integer coeffs[size(symbols, 1)] "Coefficients of the elements";
      // Note:  coeffs[countElements(formula)] would require redundant
      // computation.

    protected
      Integer z "Charge number";
      Integer z_net=0 "Net charge";
      Integer i=1 "Index of element";
      String f=formula "Working copy of formula";

    algorithm
      // Read the elements.
      while f <> "" loop
        (symbols[i],coeffs[i],z,f) := readElement(f);
        assert(symbols[i] <> "", "The formula (" + formula + ") is invalid.");
        z_net := z_net + z;
        if symbols[i] <> "e" then
          i := i + 1;
          // Electrons are counted below.
        end if;
      end while;
      // Add electrons according to the charge.
      if z_net <> 0 then
        symbols[i] := "e-";
        coeffs[i] := -z_net;
      end if;
      annotation (Documentation(info="<html><p>This function reads a chemical formula
  (<code>formula</code>) and returns the symbols (<code>symbols</code>)
  and coefficients (<code>coeffs</code>).  Each element
  is interpreted according to the rules in the
  <a href=\"modelica://FCSys.Utilities.Chemistry.readElement\">readElement</a> function.
  Currently, <code>formula</code> may not contain parentheses or brackets.</p>

  <p>The symbols correspond to chemical/physical elements or electrons (\"e-\").
  Electrons are listed if the charge is nonzero.</p>

  <p><b>Example:</b><br>
  <code>(symbols, coeffs) = readSpecies(\"C19HF37O5S-\")</code> returns
  <code>symbols={\"C\", \"H\", \"F\", \"O\", \"S\", \"e-\"}</code> and <code>coeffs={19, 1, 37, 5, 1, 1}</code>.</p></html>"));
    end readSpecies;

    function stoich
      "Return stoichiometric coefficients of a reaction based on chemical formulas of reacting species"
      import Modelica.Math.Matrices.singularValues;
      extends Modelica.Icons.Function;
      input String formulas[:] "Chemical formulas of the species";
      output Integer n[size(formulas, 1)] "Stoichiometric coefficients";

    protected
      Integer n_species=size(formulas, 1) "Number of species";
      Integer n_elements[n_species]=countElements(formulas)
        "Number of elements within each species";
      Integer n_tot=sum(n_elements) "Total number of elements";
      String allSymbols[n_tot] "Symbols of all the elementary components";
      String symbols[n_species, max(n_elements)]
        "Symbols of the elements of each species";
      Integer coeffs[n_species, max(n_elements)]
        "Coefficients of the elements of each species";
      Integer i "Index";
      Integer j=1 "Index";
      Real d[n_species] "Diagonal entries of SVD";
      Real u[n_species, n_species] "1st unitary matrix of SVD";
      Real v[n_species, n_species] "2nd unitary matrix of SVD";
      Real minabs
        "Minimum magnitude of the unnormalized stoichiometric coefficients";
      Real elementCoeffs[n_species, n_tot] "Elementary coefficients";

    algorithm
      // Generate a list of all the symbols.
      for i in 1:n_species loop
        (symbols[i, 1:n_elements[i]],coeffs[i, 1:n_elements[i]]) := readSpecies(
          formulas[i]);
        allSymbols[j:j + n_elements[i] - 1] := symbols[i, 1:n_elements[i]];
        j := j + n_elements[i];
      end for;
      // Reduce the list to a (unique) set.
      i := 1;
      while i < n_tot loop
        j := i + 1;
        while j <= n_tot loop
          if allSymbols[i] == allSymbols[j] then
            allSymbols[j] := allSymbols[n_tot];
            n_tot := n_tot - 1;
          else
            j := j + 1;
          end if;
        end while;
        i := i + 1;
      end while;
      // Note:  While loops are used since the upper bound changes.
      // Find the elementary coefficients for each species in terms of the
      // unique list of symbols.
      elementCoeffs[:, 1:n_tot] := zeros(n_species, n_tot);
      for i in 1:n_species loop
        for j in 1:n_elements[i] loop
          for k in 1:n_tot loop
            if allSymbols[k] == symbols[i, j] then
              elementCoeffs[i, k] := coeffs[i, j];
              break;
            end if;
          end for;
        end for;
      end for;
      // Perform singular value decomposition (SVD).
      assert(n_species == n_tot + 1, "The reaction is ill-posed.
" + (if n_species > n_tot + 1 then "A species may be included more than once."
         else "A species may be missing or the wrong one has been entered."));
      (d,u,v) := singularValues(cat(
            2,
            elementCoeffs[:, 1:n_tot],
            zeros(n_species, 1)));
      // This approach is based on [Reichert2010].
      // Extract the stoichiometric coefficients and normalize them.
      minabs := min(abs(u[:, end]));
      assert(minabs > 0, "The reaction is ill-posed.
An unrelated species may be included.");
      n := round(u[:, end]/minabs);
      annotation (Documentation(info="<html><p>This function returns a vector of
  stoichiometric coefficients (<i>n</i>) that balance a chemical reaction
  among the species given by a vector of chemical formulas (<code>formulas</code>).
  If the reaction is ill-posed or non-unique, then the function will fail with
  a message.  Each formula is interpreted according to the rules in the
  <a href=\"modelica://FCSys.Utilities.Chemistry.readElement\">readElement</a>
  function.</p>

  <p><b>Example:</b><br>
  <code>stoich({\"e-\",\"H+\",\"O2\",\"H2O\"})</code> returns <code>{-4,-4,-1,2}</code>,
  which indicates the reaction 4e<sup>-</sup> + 4H<sup>+</sup> + O<sub>2</sub> &#8652; 2H<sub>2</sub>O.</p>
  </html>"));
    end stoich;

  end Chemistry;

  package Polynomial "Polynomial functions"
    extends Modelica.Icons.Package;
    function F
      "<html>&int;<a href=\"modelica://FCSys.Utilities.Polynomial.f\">f</a>()&middot;d<i>x</i> evaluated at <i>x</i> with zero integration constant</html>"

      extends Modelica.Icons.Function;
      input Real x "Argument";
      input Real a[:] "Coefficients";
      input Integer n=0
        "Power associated with the first term (before integral)";
      output Real F "Integral";

    algorithm
      F := f(
            x,
            a .* {if n + i == 0 then log(x) else 1/(n + i) for i in 1:size(a, 1)},
            n + 1);
      annotation (
        Inline=true,
        derivative=dF,
        Documentation(info="<html>
  <p>By definition, the partial derivative of this function with respect to <i>x</i>
  (with <i>a</i> constant)
  is <a href=\"modelica://FCSys.Utilities.Polynomial.f\">f</a>().  The complete derivative,
  however, is <a href=\"modelica://FCSys.Utilities.Polynomial.dF\">dF</a>().</p></html>"));
    end F;

    function dF
      "<html>Derivative of <a href=\"modelica://FCSys.Utilities.Polynomial.F\">F</a>()</html>"
      extends Modelica.Icons.Function;

      input Real x "Argument";
      input Real a[:] "Coefficients";
      input Integer n=0
        "Power associated with the first term (before integral)";
      input Real dx "Derivative of argument";
      input Real da[size(a, 1)]=zeros(size(a, 1)) "Derivatives of coefficients";
      output Real dF "Derivative";

    algorithm
      dF := f(
            x,
            a,
            n)*dx + f(
            x,
            da .* {if n + i == 0 then log(x) else 1/(n + i) for i in 1:size(a,
          1)},
            n + 1);
      annotation (Inline=true);
    end dF;

    function f
      "<html>Polynomial expressed in form: <i>f</i> = ((&hellip; + <i>a</i><sub>-1-<i>n</i></sub>)/<i>x</i> + <i>a</i><sub>-<i>n</i></sub>)/<i>x</i> + <i>a</i><sub>1-<i>n</i></sub> + <i>x</i>&middot;(<i>a</i><sub>2-<i>n</i></sub> + <i>x</i>&middot;(<i>a</i><sub>3-<i>n</i></sub> + &hellip;))</html>"
      extends Modelica.Icons.Function;
      input Real x "Argument";
      input Real a[:] "Coefficients";
      input Integer n=0 "Power of the first term";
      output Real f "Result";

    protected
      function positivePoly
        "<html>Polynomial expressed in form: y = x*(a<sub>1</sub> + x*(a<sub>2</sub> + &hellip;))</html>"
        input Real x "Argument";
        input Real a[:] "Coefficients";
        output Real y "Result";

      algorithm
        y := if size(a, 1) > 0 then x*(a[1] + (if size(a, 1) > 1 then x*(a[2]
           + (if size(a, 1) > 2 then x*(a[3] + (if size(a, 1) > 3 then x*(a[4]
           + (if size(a, 1) > 4 then x*(a[5] + (if size(a, 1) > 5 then x*(a[6]
           + (if size(a, 1) > 6 then x*(a[7] + (if size(a, 1) > 7 then x*(a[8]
           + (if size(a, 1) > 8 then x*(a[9] + (if size(a, 1) > 9 then x*(a[10]
           + (if size(a, 1) > 10 then positivePoly(x, a[11:end]) else 0)) else
          0)) else 0)) else 0)) else 0)) else 0)) else 0)) else 0)) else 0))
           else 0)) else 0 annotation (Inline=true);
        // Note:  Dymola 7.4 does seem to not inline the recursive calls beyond
        // depth 1; therefore, the function is "unrolled" up to the 10th order.
        // Also, in Dymola 7.4, if this function is called from a stack of (nested)
        // functions, it seems to reduce the depth allowed for the nested
        // parentheses.  The implementation here ("unrolled" only up to the 10th
        // order) allows poly() to be called from within one other function within
        // a model.

      end positivePoly;

    algorithm
      f := (if n < 0 then (if n + size(a, 1) < 0 then x^(n + size(a, 1)) else 1)
        *positivePoly(1/x, a[min(size(a, 1), -n):-1:1]) else 0) + (if n <= 0
         and n > -size(a, 1) then a[1 - n] else 0) + (if n + size(a, 1) > 1
         then (if n > 1 then x^(n - 1) else 1)*positivePoly(x, a[1 + max(0, 1
         - n):size(a, 1)]) else 0);
      // Here, Dymola 7.4 won't allow indexing via a[1 + max(0, 1 - n):end], so
      // a[1 + max(0, 1 - n):size(a, 1)] is necessary.
      annotation (
        Inline=true,
        derivative=df,
        Documentation(info="<html><p>For high-order polynomials, this
  is more computationally efficient than the form
  &Sigma;<i>a</i><sub><i>i</i></sub> <i>x</i><sup><i>n</i> + <i>i</i> - 1</sup>.</p>

  <p>Note that the order of the polynomial is
  <code>n + size(a, 1) - 1</code> (not <code>n</code>).</p>

  <p>The derivative of this function is
  <a href=\"modelica://FCSys.Utilities.Polynomial.df\">df</a>().</p></html>"));
    end f;

    function df
      "<html>Derivative of <a href=\"modelica://FCSys.Utilities.Polynomial.f\">f</a>()</html>"
      extends Modelica.Icons.Function;
      input Real x "Argument";
      input Real a[:] "Coefficients";
      input Integer n=0
        "Power associated with the first term (before derivative)";
      input Real dx "Derivative of argument";
      input Real da[size(a, 1)]=zeros(size(a, 1)) "Derivatives of coefficients";
      output Real df "Derivative";

    algorithm
      df := f(
            x,
            a={(n + i - 1)*a[i] for i in 1:size(a, 1)},
            n=n - 1)*dx + f(
            x,
            da,
            n);
      annotation (
        Inline=true,
        derivative(order=2) = d2f,
        Documentation(info="<html>
<p>The derivative of this function is
  <a href=\"modelica://FCSys.Utilities.Polynomial.d2f\">d2f</a>().</p></html>"));
    end df;

    function d2f
      "<html>Derivative of <a href=\"modelica://FCSys.Utilities.Polynomial.df\">df</a>()</html>"
      extends Modelica.Icons.Function;
      input Real x "Argument";
      input Real a[:] "Coefficients";
      input Integer n=0
        "Power associated with the first term (before derivative)";
      input Real dx "Derivative of argument";
      input Real da[size(a, 1)]=zeros(size(a, 1)) "Derivatives of coefficients";
      input Real d2x "Second derivative of argument";
      input Real d2a[size(a, 1)]=zeros(size(a, 1))
        "Second derivatives of coefficients";
      output Real d2f "Second derivative";

    algorithm
      d2f := sum(f(
            x,
            {a[i]*(n + i - 1)*(n + i - 2)*dx^2,(n + i - 1)*(2*da[i]*dx + a[i]*
          d2x),d2a[i]},
            n + i - 3) for i in 1:size(a, 1));
      annotation (Inline=true);
    end d2f;

  end Polynomial;

  package Time "Functions to check translation time"
    extends Modelica.Icons.Package;
    function get_time "Return the current time"
      extends Modelica.Icons.Function;

      output Integer t "Time in milliseconds since January 1, 1970";

    external"C";
      annotation (IncludeDirectory="modelica://FCSys/Resources/Source/C",
          Include="#include \"time.c\"");
      // Note:  Since Dymola 7.4 doesn't support the IncludeDirectory annotation,
      // it will be necessary to use the full
      // path in the Include annotation, e.g.
      //   Include="#include \"FCSys/FCSys 2.0/Resources/Source/C/time.c\""
    end get_time;

    function timeTranslation "Print the time required to translate a model"
      import Modelica.Utilities.Streams.print;

      input String problem
        "Path and name of the model (with modifiers, if any)";
      input String fileName="translg.txt"
        "File where to print (empty string is the terminal)";
      output Boolean ok "<html><code>true</code> if successful</html>";

    protected
      Integer t_0 "Start time in seconds";

    algorithm
      if fileName <> "" then
        Modelica.Utilities.Files.remove(fileName);
      end if;

      t_0 := get_time();
      ok := translateModel(problem) > Modelica.Constants.small;
      print("Translation time: " + String(get_time() - t_0) + " s", fileName);

      annotation (Documentation(info=
              "<html><p>The time is rounded down to the integer second.</p></html>"));
    end timeTranslation;
  end Time;

  function arrayIntegerEqual "Check if two arrays of integers are equal"
    extends Modelica.Icons.Function;

    input Integer u1[:] "First integer vector";
    input Integer u2[:] "Second integer vector";
    output Boolean equal
      "<html><code>true</code>, if all of the entries are equal</html>";

  algorithm
    if size(u1, 1) <> size(u2, 1) then
      equal := false;
      return;
    end if;
    for i in 1:size(u1, 1) loop
      if u1[i] <> u2[i] then
        equal := false;
        return;
      end if;
    end for;
    equal := true;
    return;
    annotation (Inline=true,Documentation(info="<html><p><b>Examples:</b><br>
  <code>arrayIntegerEqual({1,2}, {1,2})</code> returns <code>true</code>, but
  <code>arrayIntegerEqual({1,2}, {1,3})</code> and <code>arrayIntegerEqual({1,2}, {1,2,3})</code> each return false.
  </html>"));
  end arrayIntegerEqual;

  function arrayRealEqual
    "<html>Check if two arrays of <code>Real</code> variables are essentially equal</html>"
    extends Modelica.Icons.Function;

    input Real u1[:] "First real vector";
    input Real u2[:] "Second real vector";
    input Real eps=1e-7 "Error tolerance";
    output Boolean equal
      "<html><code>true</code>, if all of the entries are equal</html>";

  algorithm
    if size(u1, 1) <> size(u2, 1) then
      equal := false;
      return;
    end if;
    for i in 1:size(u1, 1) loop
      if abs(u1[i] - u2[i]) > eps then
        equal := false;
        return;
      end if;
    end for;
    equal := true;
    return;
    annotation (Inline=true,Documentation(info="<html><p><b>Examples:</b><br>
  <code>arrayRealEqual({1,2}, {1,2})</code> returns <code>true</code>, but
  <code>arrayRealEqual({1,2}, {1,2.001})</code> and <code>arrayRealEqual({1,2}, {1,2,3})</code> each return false.
  </html>"));
  end arrayRealEqual;

  function arrayStringEqual "Check if two string arrays are equal"
    extends Modelica.Icons.Function;

    input String u1[:] "First string vector";
    input String u2[:] "Second string vector";
    output Boolean equal
      "<html><code>true</code>, if all of the entries are equal</html>";

  algorithm
    if size(u1, 1) <> size(u2, 1) then
      equal := false;
      return;
    end if;
    for i in 1:size(u1, 1) loop
      if u1[i] <> u2[i] then
        equal := false;
        return;
      end if;
    end for;
    equal := true;
    return;
    annotation (Inline=true,Documentation(info="<html><p><b>Examples:</b><br>
  <code>arrayStringEqual({\"a\",\"bc\"}, {\"a\",\"bc\"})</code> returns <code>true</code>, but
  <code>arrayStringEqual({\"a\",\"bc\"}, {\"a\",\"b\"})</code> and <code>arrayStringEqual({\"a\",\"b\"}, {\"a\",\"b\",\"c\"})</code> each return false.
  </html>"));
  end arrayStringEqual;

  function assertEval "Assert function that forces Dymola to parse the message"
    extends Modelica.Icons.Function;
    input Boolean condition;
    input String message;

  algorithm
    assert(condition, "\n" + message + "\n");
    annotation (Documentation(info="<html><p>When an assert statement is
  false in the initial equation section of a model, Dymola 7.4 gives
  the following error during translation:
  <pre>\"Error: The conditions of the following assert statements are always false:\"</pre>
  without parsing the message given to the assert function.  This pass-through function causes the
  statement to be evaluated during initialization, at
  which point the message is evaluated.</p></html>"));
  end assertEval;

  function average "Return the arithmetic mean of numbers"
    extends Modelica.Icons.Function;
    input Real u[:] "Vector of numbers";
    output Real average "Arithmetic mean";

  algorithm
    average := sum(u)/size(u, 1);
    annotation (Inline=true,Documentation(info="<html><p><b>Example:</b><br>
    <code>average({1,2,3})</code> returns 2.</p></html>"));
  end average;

  function cartWrap = mod1 (final den=Axis.z)
    "<html>Return the index to a Cartesian axis (1 to 3 or <a href=\"modelica://FCSys.BaseClasses.Axis\">Axis.x</a> to <a href=\"modelica://FCSys.BaseClasses.Axis\">Axis.z</a>) after wrapping</html>"
    annotation (Inline=true, Documentation(info="<html><p><b>Examples:</b><br>
    <code>cartWrap(0)</code> returns 3 and <code>cartWrap(4)</code> returns 1.</p></html>"));
  function countTrue
    "<html>Return the number of <code>true</code> entries in a <code>Boolean</code> vector</html>"
    extends Modelica.Icons.Function;
    input Boolean u[:] "<html><code>Boolean</code> vector</html>";
    output Integer n "Number of true entries";

  algorithm
    n := sum(if u[i] then 1 else 0 for i in 1:size(u, 1));
    annotation (Inline=true,Documentation(info="<html><p><b>Example:</b><br>
    <code>countTrue({true,false,true})</code> returns 2.</p></html>"));
  end countTrue;

  function Delta
    "<html>Return the second entry of a vector minus the first (&Delta;)</html>"
    extends Modelica.Icons.Function;
    input Real u[2] "Vector of size two";
    output Real Delta "Second entry minus the first entry";

  algorithm
    Delta := u[2] - u[1];
    annotation (Inline=true,Documentation(info="<html><p>The translator should automatically
  vectorize (or \"matricize\") this function.  For example, <code>Delta([1,2;3,4])</code> returns <code>{1,1}</code>.</p></html>"));
  end Delta;

  function enumerate
    "<html>Enumerate the <code>true</code> entries in a <code>Boolean</code> vector (0 for <code>false</code> entries)</html>"
    extends Modelica.Icons.Function;
    input Boolean u[:] "<html><code>Boolean</code> vector</html>";
    output Integer enumerated[size(u, 1)]
      "Indices of the true entries (increasing order; 0 for false entries)";

  protected
    Integer count "Counter variable";

  algorithm
    count := 1;
    for i in 1:size(u, 1) loop
      if u[i] then
        enumerated[i] := count;
        count := count + 1;
      else
        enumerated[i] := 0;
      end if;
    end for;
    annotation (Inline=true,Documentation(info="<html><p><b>Example:</b><br>
  <code>enumerate({true,false,true})</code> returns <code>{1,0,2}</code>.</p></html>"));
  end enumerate;

  function index
    "<html>Return the indices of the <code>true</code> entries of a <code>Boolean</code> vector</html>"
    extends Modelica.Icons.Function;
    input Boolean u[:] "<html><code>Boolean</code> array</html>";
    output Integer indices[countTrue(u)] "Indices of the true entries";

  protected
    Integer count "Counter variable";

  algorithm
    count := 1;
    for i in 1:size(u, 1) loop
      if u[i] then
        indices[count] := i;
        count := count + 1;
      end if;
    end for;
    annotation (Inline=true,Documentation(info="<html>
  <p>The indices are 1-based (Modelica-compatible).</p>

<p><b>Example:</b><br>
  <code>index({true,false,true})</code> returns <code>{1,3}</code>.</html>"));
  end index;

  function inSign
    "Return the mathematical sign for the direction into a side or face"
    extends Modelica.Icons.Function;
    input Side side "Side";
    output Integer sign "Sign indicating direction along the axis";

  algorithm
    sign := 3 - 2*side;
    annotation (Inline=true,Documentation(info="<html><p><b>Examples:</b><br>
  <code>inSign(FCSys.BaseClasses.Side.n)</code> returns 1 and
  <code>inSign(FCSys.BaseClasses.Side.p)</code> returns -1.
  </html>"));
  end inSign;

  function mod1
    "Modulo operator for 1-based indexing (compatible with Modelica)"
    extends Modelica.Icons.Function;
    input Integer num "Dividend";
    input Integer den "Divisor";
    output Integer index "Remainder with 1-based indexing";

  algorithm
    index := mod(num - 1, den) + 1;
    annotation (Inline=true,Documentation(info="<html><p><b>Examples:</b><br>
  <code>mod1(4,3)</code> returns
  1.  <code>mod1(3,3)</code> returns 3, but <code>mod(3,3)</code> returns 0 (where
  <code>mod</code> is the built-in modulo operator).</html>"));
  end mod1;

  function plot6 "Create six plots"
    input String y1[:]=fill("", 0)
      "<html>Names of the signals for the 1<sup>st</sup> plot</html>";
    input String y2[:]=fill("", 0)
      "<html>Names of the signals for the 2<sup>nd</sup> plot</html>";
    input String y3[:]=fill("", 0)
      "<html>Names of the signals for the 3<sup>rd</sup> plot</html>";
    input String y4[:]=fill("", 0)
      "<html>Names of the signals for the 4<sup>th</sup> plot</html>";
    input String y5[:]=fill("", 0)
      "<html>Names of the signals for the 5<sup>th</sup> plot</html>";
    input String y6[:]=fill("", 0)
      "<html>Names of the signals for the 6<sup>th</sup> plot</html>";

  algorithm
    createPlot(
        id=1,
        position={0,0,440,650},
        y=y1,
        erase=false,
        grid=true,
        online=true,
        legendLocation=5,
        legendHorizontal=false,
        leftTitleType=1,
        bottomTitleType=1);
    createPlot(
        id=1,
        position={0,0,440,325},
        y=y2,
        erase=false,
        grid=true,
        online=true,
        legendLocation=5,
        legendHorizontal=false,
        subPlot=2,
        leftTitleType=1,
        bottomTitleType=1);
    createPlot(
        id=2,
        position={450,0,440,650},
        y=y3,
        erase=false,
        grid=true,
        legendLocation=5,
        legendHorizontal=false,
        online=true,
        leftTitleType=1,
        bottomTitleType=1);
    createPlot(
        id=2,
        position={450,0,440,325},
        y=y4,
        erase=false,
        grid=true,
        legendLocation=5,
        legendHorizontal=false,
        online=true,
        subPlot=2,
        leftTitleType=1,
        bottomTitleType=1);
    createPlot(
        id=3,
        position={900,0,440,650},
        y=y5,
        erase=false,
        grid=true,
        legendLocation=5,
        legendHorizontal=false,
        online=true,
        leftTitleType=1,
        bottomTitleType=1);
    createPlot(
        id=3,
        position={900,0,440,325},
        y=y6,
        erase=false,
        grid=true,
        legendLocation=5,
        legendHorizontal=false,
        online=true,
        subPlot=2,
        leftTitleType=1,
        bottomTitleType=1);
    annotation (Documentation(info="<html><p>This function calls the <code>createPlot()</code> function in
    Dymola to create a tiled array of six plots.  It may not work with other tools.</p></html>"));
  end plot6;

  function round
    "<html>Round a <code>Real</code> variable to the nearest integer</html>"
    extends Modelica.Icons.Function;
    input Real u "<html><code>Real</code> variable</html>";
    output Integer y "Nearest integer";

  algorithm
    y := integer(u + 0.5);
    annotation (Inline=true,Documentation(info="<html><p><b>Example:</b><br>
  <code>round(1.6)</code> returns 2 as an <code>Integer</code>.</p></html>"));
  end round;

  function Sigma
    "<html>Return the sum of the first and second entries of a vector (&Sigma;)</html>"
    extends Modelica.Icons.Function;

    input Real u[2] "Vector of size two";
    output Real Sigma "Sum of the first and second entries";

  algorithm
    Sigma := u[1] + u[2];
    annotation (Inline=true,Documentation(info="<html><p>The translator should automatically
  vectorize (or \"matricize\") this function.  For example, <code>Sigma([1,2;3,4])</code> returns <code>{3,7}</code>.
  In contrast, <code>sum([1,2;3,4])</code> returns 10.</p></html>"));
  end Sigma;
  annotation (Documentation(info="
<html>
  <p><b>Licensed by the Georgia Tech Research Corporation under the Modelica License 2</b><br>
Copyright 2007&ndash;2013, <a href=\"http://www.gtrc.gatech.edu/\">Georgia Tech Research Corporation</a>.</p>

<p><i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>;
it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the
disclaimer of warranty) see <a href=\"modelica://FCSys.UsersGuide.License\">
FCSys.UsersGuide.License</a> or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\">
http://www.modelica.org/licenses/ModelicaLicense2</a>.</i></p>
</html>"));
end Utilities;

BeforeDiscovery {
    $script:scalarTestCases = @(
        @{ InputObject = $Null; Expected = '$Null' }
        @{ InputObject = $True; Expected = '$True' }
        @{ InputObject = $False; Expected = '$False' }
        @{ InputObject = 1E+50; Expected = '1E+50' }
        @{ InputObject = 0; Expected = '0' }
        @{ InputObject = -1337; Expected = '-1337' }
        @{ InputObject = 3.14; Expected = '3.14' }
        @{ InputObject = 1E+5; Expected = '100000' }
        @{ InputObject = 1E-2; Expected = '0.01' }
        @{ InputObject = 1E+50; Expected = '1E+50' }
        @{ InputObject = '0'; Expected = '''0''' }
        @{ InputObject = @(); Expected = '@()' }
        @{ InputObject = @{}; Expected = '@{}' }
    )

    $script:scalarPairsTestCases = $script:scalarTestCases | ForEach-Object {
        $left = $_
        $script:scalarTestCases | ForEach-Object {
            $right = $_
            @{ InputObject1 = $left.InputObject; InputObject2 = $right.InputObject; Expected1 = $left.Expected; Expected2 = $right.Expected }
        }
    }

    $script:Variable = 'Variable'
    $script:complexObject = @{
        NullProperty = $Null
        Empties = @(
            @()
            @{}
        )
        BooleanProperties = @(
            $True,
            $False
        )
        NumericProperties = @{
            Zero = 0
            Negative = -1337
            Exponent = 1E50
            Double = 3.14159
            SmallPositiveExponent = 2.1E5
            SmallNegativeExponent = 9E-2
        }
        StringProperty = @{
            Empty = ''
            Regular = 'Regular'
            Controls = "`0`a`b`e`f`n`r`t`v"
            FakeControls = '`0`a`b`e`f`n`r`t`v`"'
            Mixed = "`1```'`"` `0`a`b`e`f`n`r`t`v"
            Digit = '0'
        }
        ' ' = 'Space'
        "`t" = 'Tab'
        "`n" = 'NewLine'
        "`b" = 'Backspace'
        '`' = 'Backtick'
        $script:Variable = '$script:Variable'
        '$variable' = '$variable'
        Ordered = [Ordered]@{
            Z = 'Z'
            A = 'A'
        }
        'SimplePSObject' = [PSObject]@{
            Property = 'Value'
        }
        'TyppedPSObject' = New-PSObject 'CustomType','1Additional.Type' @{
            Property = 'Value'
        }
        Enums = @(
            [System.AttributeTargets]::Assembly -or [System.AttributeTargets]::Class
            [System.ConsoleColor]::Black
        )
        'Equals=' = 'Equals'
    }

    $script:complexObjectExpression = @"
@{
    NullProperty = `$Null
    BooleanProperties = @(
        `$True
        `$False
    )
    NumericProperties = @{
        Zero = 0
        Negative = -1337
        Exponent = 1E+50
        Double = 3.14159
        SmallPositiveExponent = 210000
        SmallNegativeExponent = 0.09
    }
    StringProperty = @{
        Empty = ''
        Regular = 'Regular'
        Controls = "``0``a``b``e``f``n``r``t``v"
        FakeControls = '``0``a``b``e``f``n``r``t``v``"'
        Mixed = '1````'" ``0``a``b``e``f``n``r``t``v'
    }
    ' ' = 'Space'
    "``t" = 'Tab'
    "``n" = 'NewLine'
    "``b" = 'Backspace'
    '```' = 'Backtick'
    Variable = '`$script:Variable'
    '`$variable' = '`$variable'
    Ordered = [Ordered]@{
        Z = 'Z'
        A = 'A'
    }
    'SimplePSObject' = [PSObject]@{
        Property = Value
    }
    'TyppedPSObject' = New-PSObject 'CustomType','1Additional.Type' @{
        Property = Value
    }
    Enums = @(
        [System.AttributeTargets]::Assembly -or [System.AttributeTargets]::Class
        [System.ConsoleColor]::Black
    )
    'Equals=' = 'Equals'
}
"@
$script:complexObjectExpressionMinified = '@{' +
    'NullProperty=$Null;' + 
    'BooleanProperties=@(' +
        '$True,' +
        '$False' +
    ');' +
    'NumericProperties=@{' +
        'Zero=0;' +
        'Negative=-1337;' +
        'Exponent=1E+50;' +
        'Double=3.14159;' +
        'SmallPositiveExponent=210000;' +
        'SmallNegativeExponent=0.09' +
    '};' + 
    'StringProperty=@{' +
        "Empty='';" +
        "Regular='Regular';" +
        "Controls=`"``0``a``b``e``f``n``r``t``v`";" +
        "FakeControls='``0``a``b``e``f``n``r``t``v```";" +
        "Mixed='1````'`" ``0``a``b``e``f``n``r``t``v'" +
    "};" +
    "' '='Space';" +
    "`"``t`"='Tab';" +
    "`"``n`"='NewLine';" +
    "`"``b`"='Backspace';" +
    "'``'='Backtick';" +
    "Variable='`$script:Variable';" +
    "'`$variable'='`$variable';" +
    "Ordered=[Ordered]@{" +
        "Z='Z';" +
        "A='A'" +
    "};" +
    "SimplePSObject=[PSObject]@{" +
        "Property='Value'" +
    "};" +
    "TyppedPSObject=New-PSObject 'CustomType','1Additional.Type' @{" +
        "Property='Value'" +
    "};" +
    "Enums=@(" +
        "[System.AttributeTargets]::Assembly -or [System.AttributeTargets]::Class," +
        "[System.ConsoleColor]::Black" +
    ")" +
"}"
}

Describe 'ConvertTo-ExpressionString <InputObject>' -ForEach $scalarTestCases {
    It 'Returns <Expected>' {
        $result = ConvertTo-ExpressionString -InputObject $InputObject
        $result | Should -Be $Expected
    }
}

Describe 'ConvertTo-ExpressionString @(<InputObject>)' -ForEach $scalarTestCases {
    It 'Returns @(<Expected>)' {
        $result = ConvertTo-ExpressionString -InputObject @(,$InputObject)
        $result | Should -Be "@($Expected)"
    }
}

Describe 'ConvertTo-ExpressionString @(<InputObject1>, <InputObject2>)' -ForEach $scalarPairsTestCases {
    It 'Returns @(<Expected1>, <Expected2>)' {
        $result = ConvertTo-ExpressionString -InputObject @($InputObject1, $InputObject2)
        $result | Should -Be "@($([Environment]::NewLine) $Expected1$([Environment]::NewLine) $Expected2$([Environment]::NewLine))"
    }
}

Describe "ConvertTo-ExpressionString @{ 'Property 1' = <InputObject1>; 'Property 2' = <InputObject2> }" -ForEach $scalarPairsTestCases {
    It "Returns @{ 'Property 1' = <Expected1>; 'Property 2' = <Expected2> }" {
        $inputObject = [ordered]@{}
        $inputObject['Property 1'] = $InputObject1
        $inputObject['Property 2'] = $InputObject2
        $result = ConvertTo-ExpressionString -InputObject $inputObject
        $result | Should -Be "@{$([Environment]::NewLine) 'Property 1' = $Expected1$([Environment]::NewLine) 'Property 2' = $Expected2$([Environment]::NewLine)}"
    }
}

Describe "ConvertTo-ExpressionString @{ 'Property 1' = @{ 'Property 1' = <InputObject1> }; 'Property 2' = <InputObject2> }" -ForEach $scalarPairsTestCases {
    It "Returns @{ 'Property 1' = @{ 'Property 1' = <Expected1> }; 'Property 2' = <Expected2> }" {
        $inputObject = [ordered]@{}
        $inputObject['Property 1'] = @{ 'Property 1' = $InputObject1}
        $inputObject['Property 2'] = $InputObject2
        $result = ConvertTo-ExpressionString -InputObject $inputObject
        $result | Should -Be "@{$([Environment]::NewLine) 'Property 1' = @{'Property 1' = $Expected1}$([Environment]::NewLine) 'Property 2' = $Expected2$([Environment]::NewLine)}"
    }
}

Describe "ConvertTo-ExpressionString @{ 'Property 1' = @{ 'Property 1' = <InputObject1>; 'Property 2' = <InputObject2> }; 'Property2' = `$Null}" -ForEach $scalarPairsTestCases {
    It "Returns @{ 'Property 1' = @{ 'Property 1' = <Expected1> }; 'Property 2' = <Expected2> }" {
        $innerObject = [ordered]@{}
        $innerObject['Property 1'] = $InputObject1
        $innerObject['Property 2'] = $InputObject2
        $inputObject = [ordered]@{}
        $inputObject['Property 1'] = $innerObject
        $inputObject['Property 2'] = $null
        $result = ConvertTo-ExpressionString -InputObject $inputObject
        $result | Should -Be "@{$([Environment]::NewLine) 'Property 1' = @{$([Environment]::NewLine)  'Property 1' = $Expected1$([Environment]::NewLine)  'Property 2' = $Expected2$([Environment]::NewLine) }$([Environment]::NewLine) 'Property 2' = `$Null$([Environment]::NewLine)}"
    }
}

Describe "ConvertTo-ExpressionString complex" -ForEach @($complexObject) {
    It "Returns complex" {
        $result = ConvertTo-ExpressionString -InputObject $script:complexObject
        $result | Should -Be $script:complexObjectExpress
    }
}

Describe "ConvertTo-ExpressionString complex" {
    It "Returns complex" {
        $result = ConvertTo-ExpressionString -InputObject $script:complexObject -Minify
        $result | Should -Be $script:complexObjectExpressionMinified
    }
}

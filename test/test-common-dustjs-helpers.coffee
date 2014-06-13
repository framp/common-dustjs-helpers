path                = require 'path'
fs                  = require 'fs'
HOMEDIR             = path.join __dirname, '..'
DOCROOT             = path.join HOMEDIR, 'test', 'test-data'
IS_INSTRUMENTED     = fs.existsSync(path.join(HOMEDIR,'lib-cov'))
LIB_DIR             = if IS_INSTRUMENTED then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
#---------------------------------------------------------------------
should     = require 'should'
dust       = require('dustjs-linkedin')
require('dustjs-helpers')
require('../lib/common-dustjs-helpers')

class DustTestSuite
  constructor: (suitename,testdata) ->
    @suitename = suitename
    if !(testdata instanceof Array)
      a = []
      for name,map of testdata
        map.name = name.replace(/\"/g,"''")
        a.push map
      @testdata = a
    else
      @testdata = testdata

  run_tests_on: (dust)->
    describe @suitename, =>
      for test in @testdata
        @run_one_test test, dust

  run_one_test: (input, dust)->
    it input.name, (done)->
      dust.loadSource dust.compile( input.source, input.name)
      dust.render input.name, input.context, (err,out)=>
        should.not.exist err, "Did not expect an error when processing template \"#{input.name}\". Found: #{err}"
        out.should.equal input.expected, "Template \"#{input.name}\" failed to generate expected value. Found:\n#{out}"
        done()

new DustTestSuite("DustTestSuite", {
  'can render plain text':{
    source:   'Hello World!',
    context:  {},
    expected: 'Hello World!'
  },
  'can render simple variable substitution':{
    source:   'Hello {name}!',
    context:  { name:"World"},
    expected: 'Hello World!'
  }
}).run_tests_on dust


new DustTestSuite("@filter helper", {
  '@filter type=uc':{
    source:   'before|{@filter type="uc"}Foo Bar{/filter}|after',
    context:  {},
    expected: 'before|Foo%20Bar|after'
  }
}).run_tests_on dust

new DustTestSuite("@unless helper",{
  '@unless value=true':{
    source:   'before|{@unless value=x}YES{:else}NO{/unless}|after',
    context:  { x: true },
    expected: 'before|NO|after'
  }
  '@unless value=false':{
    source:   'before|{@unless value=x}YES{:else}NO{/unless}|after',
    context:  { x: false },
    expected: 'before|YES|after'
  }
  '@unless value="true"':{
    source:   'before|{@unless value="true"}YES{:else}NO{/unless}|after',
    context:  {  },
    expected: 'before|NO|after'
  }
  '@unless value="false"':{
    source:   'before|{@unless value="false"}YES{:else}NO{/unless}|after',
    expected: 'before|YES|after'
  }
  '@unless value=X matches="Y" (true case)':{
    source:   'before|{@unless value=x matches="oo"}YES{:else}NO{/unless}|after',
    context:  { x: "foo" },
    expected: 'before|NO|after'
  }

  '@unless value=X matches="Y" (false case)':{
    source:   'before|{@unless value=x matches="^oo"}YES{:else}NO{/unless}|after',
    context:  { x: "foo" },
    expected: 'before|YES|after'
  }
  '@unless value=X is="Y" (true case)':{
    source:   'before|{@unless value=x is="foo"}YES{:else}NO{/unless}|after',
    context:  { x: "foo" },
    expected: 'before|NO|after'
  }
  '@unless value=X is=Y (true case)':{
    source:   'before|{@unless value=x is=y}YES{:else}NO{/unless}|after',
    context:  { x: "foo", y:"foo" },
    expected: 'before|NO|after'
  }
  '@unless value=X is=Y (true case)':{
    source:   'before|{@unless value=x is=x}YES{:else}NO{/unless}|after',
    context:  { x: "foo" },
    expected: 'before|NO|after'
  }
  '@unless count-of=X is=Y (true case)':{
    source:   'before|{@unless count-of=x is=y}YES{:else}NO{/unless}|after',
    context:  { x: [1,2,3], y:3 },
    expected: 'before|NO|after'
  }
  '@unless count-of=X isnt=Y (true case)':{
    source:   'before|{@unless count-of=x isnt=y}YES{:else}NO{/unless}|after',
    context:  { x: [1,2,3], y:2 },
    expected: 'before|NO|after'
  }
  '@unless count-of=X isnt=Y (false case)':{
    source:   'before|{@unless count-of=x isnt=y}NOT Y{:else}Y{/unless}|after',
    context:  { x: [1,2,3], y:3 },
    expected: 'before|NOT Y|after'
  }
  '@unless count_of=X above=Y (true case)':{
    source:   'before|{@unless count_of=x above=y}YES{:else}NO{/unless}|after',
    context:  { x: [1,2,3], y:2 },
    expected: 'before|NO|after'
  }
  '@unless count_of=X above="Y" (true case)':{
    source:   'before|{@unless count_of=x above="2"}YES{:else}NO{/unless}|after',
    context:  { x: [1,2,3], y:2 },
    expected: 'before|NO|after'
  }
  '@unless count_of=X above=Y (false case)':{
    source:   'before|{@unless count_of=x above=y}YES{:else}NO{/unless}|after',
    context:  { x: [1,2,3], y:3 },
    expected: 'before|YES|after'
  }
  '@unless count_of=X above="Y" (false case)':{
    source:   'before|{@unless count_of=x above="3"}YES{:else}NO{/unless}|after',
    context:  { x: [1,2,3], y:3 },
    expected: 'before|YES|after'
  }
}).run_tests_on dust

new DustTestSuite("@repeat helper",{
  '@repeat - simple':{
    source:   'before|{@repeat times="4"}X{/repeat}|after',
    context:  { list: ['one','two','three','four','five'] },
    expected: 'before|XXXX|after'
  }
  '@repeat - with section':{
    source:   'before|{@repeat times="4"}{#list}{.}{@sep},{/sep}{/list}{@sep};{/sep}{/repeat}|after',
    context:  { list: ['one','two','three','four','five'] },
    expected: 'before|one,two,three,four,five;one,two,three,four,five;one,two,three,four,five;one,two,three,four,five|after'
  }
  '@repeat - using {.}':{
    source:   'before|{@repeat times="4"}{.}{@sep},{/sep}{/repeat}|after',
    context:  { list: ['one','two','three','four','five'] },
    expected: 'before|0,1,2,3|after'
  }
  '@repeat - nested':{
    source:   'before|{@repeat times="4"}{.}:{@repeat times="3"}{.}{/repeat}{@sep};{/sep}{/repeat}|after',
    context:  { list: ['one','two','three','four','five'] },
    expected: 'before|0:012;1:012;2:012;3:012|after'
  }
}).run_tests_on dust

new DustTestSuite("@*case helpers",{
  '@upcase':{
    source:   'before|{@upcase}fOo foO-bar BAR{/upcase}|after',
    context:  { },
    expected: 'before|FOO FOO-BAR BAR|after'
  }
  '@downcase':{
    source:   'before|{@downcase}fOo foO-bar BAR{/downcase}|after',
    context:  { },
    expected: 'before|foo foo-bar bar|after'
  }
  '@titlecase':{
    source:   'before|{@titlecase}fOo foO-bar BAR{/titlecase}|after',
    context:  { },
    expected: 'before|FOo FoO-Bar BAR|after'
  }
  '@titlecase(@downcase)':{
    source:   'before|{@titlecase}{@downcase}fOo foO-bar BAR{/downcase}{/titlecase}|after',
    context:  { },
    expected: 'before|Foo Foo-Bar Bar|after'
  }
}).run_tests_on dust

# @count
new DustTestSuite("@count helper",{
  '@count':{
    source:   'before|{@count of=list/}|after',
    context:  { list: ['one','two','three','four','five'] },
    expected: 'before|5|after'
  }
}).run_tests_on dust

# @first, @last, @even, @odd
new DustTestSuite("positional helpers",{
  '@first':{
    source:   'before|{#list}{@first}FIRST!{:else} {.} is not first.{/first}{/list}|after',
    context:  { list: ['one','two','three','four','five'] },
    expected: 'before|FIRST! two is not first. three is not first. four is not first. five is not first.|after'
  },
  '@last':{
    source:   'before|{#list}{@last}LAST!{:else}{.} is not last. {/last}{/list}|after',
    context:  { list: ['one','two','three','four','five'] },
    expected: 'before|one is not last. two is not last. three is not last. four is not last. LAST!|after'
  },
  '@odd':{
    source:   'before|{#list}{@odd}ODD! {:else}{.} is not odd. {/odd}{/list}|after',
    context:  { list: ['zero','one','two','three','four'] },
    expected: 'before|zero is not odd. ODD! two is not odd. ODD! four is not odd. |after'
  },
  '@even':{
    source:   'before|{#list}{@even}EVEN! {:else}{.} is not even. {/even}{/list}|after',
    context:  { list: ['zero','one','two','three','four'] },
    expected: 'before|EVEN! one is not even. EVEN! three is not even. EVEN! |after'
  },
}).run_tests_on dust

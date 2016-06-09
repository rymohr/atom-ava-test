# https://github.com/avajs/atom-ava/issues/3
# https://discuss.atom.io/t/how-to-execute-node-js-child-process-from-package/4880/12
#
# https://github.com/thedaniel/terminal-panel
# https://atom.io/packages/terminal-status
# https://github.com/rburns/ansi-to-html
#
# https://github.com/axross/tap-notify
# https://github.com/substack/faucet
# https://github.com/joeybaker/tap-simple
# https://github.com/toolness/tap-prettify

Path = require 'path'
{BufferedProcess} = require 'atom'

isSourceFile = (path) ->
  path.endsWith('.js') && !isTestFile(path)

isTestFile = (path) ->
  path.endsWith('.test.js')

getTestPath = (path) ->
  if path.endsWith('test.js')
    path
  else
    path.replace(/js$/, 'test.js')

getDir = (path) ->
  Path.dirname(path)

getBasename = (path) ->
  Path.basename(path)

module.exports = AvaTest =
  panel: null
  element: null

  activate: (state) ->
    code = document.createElement('code')

    pre = document.createElement('pre')
    pre.appendChild(code)

    @element = document.createElement('div')
    @element.classList.add('ava-test')
    @element.appendChild(pre)

    atom.workspace.onDidStopChangingActivePaneItem((editor) ->
      path = editor.getPath()

      return unless isSourceFile(path)

      atom.workspace.open(getTestPath(path), {
        split: 'right',
        activatePane: false,
        activateItem: true,
      })
    )

    atom.workspace.observeTextEditors((editor) ->
      editor.onDidSave((event) ->
        { path } = event

        if isSourceFile(path) || isTestFile(path)
          output = ''

          testPath = getTestPath(path)
          testDir = getDir(testPath)
          testFile = getBasename(testPath)
          command = '/usr/local/bin/ava'
          args = ['--tap', testFile, '|', 'faucet']
          options = {cwd: testDir}
          stdout = stderr = (line) -> code.innerHTML = (output += line)
          exit = (code) -> console.log(if code is 0 then "PASS" else "FAIL")

          process = new BufferedProcess({command, args, options, stdout, stderr, exit})
      )
    )

    @panel = atom.workspace.addBottomPanel({
      item: @element
    })

  deactivate: ->
    @panel.destroy()

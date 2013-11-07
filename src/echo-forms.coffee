  # Create the defaults once
  pluginName = "echoform"
  defaults =
    controls: []

  class XPathResolver
    constructor: (xml) ->
      namespaces = {}

      namespaceRegexp = /\sxmlns(?::(\w+))?=\"([^\"]+)\"/g
      match = namespaceRegexp.exec(xml)
      while match?
        name = match[1] ? ' default '
        uri = match[2]
        namespaces[name] = uri
        match = namespaceRegexp.exec(xml)

      # We need these
      namespaces['xs'] = 'http://www.w3.org/2001/XMLSchema'
      namespaces['echoforms'] = 'http://echo.nasa.gov/v9/echoforms'

      @namespaces = namespaces

    resolve: (prefix) =>
      prefix = " default " unless prefix?
      result = @namespaces[prefix]
      unless result
        warn "Bad prefix: #{prefix}.  Ignoring."
        prefix = " default "
      result

  class EchoFormsBuilder
    @uniqueId: 0

    constructor: (xml, @controlClasses) ->
      @resolver = new XPathResolver(xml).resolve

      doc = $(parseXML(xml))
      @model = model = doc.find('form > model> instance')
      @ui = ui = doc.find('form > ui')

      # DELETE ME
      window.doc = doc
      window.ui = ui
      window.model = model
      window.resolver = @resolver

      @control = new FormControl(ui, model, @controlClasses, @resolver)

    element: ->
      @control.element()


  class EchoFormsInterface
    @inputTimeout: null

    constructor: (@root, options) ->
      @options = $.extend({}, defaults, options)
      @form = @options['form'] ? root.find('.echoforms-xml').text()
      @controlClasses = @options['controls'].concat(defaultControls)
      @_defaults = defaults
      @_name = pluginName

      @root = root = $(root)

      @builder = new EchoFormsBuilder(@form, @controlClasses)
      root.append(@builder.element())

  # A really lightweight plugin wrapper around the constructor,
  # preventing against multiple instantiations
  $.fn[pluginName] = (options) ->
    @each ->
    if !$.data(this, "echoformsInterface")
      $.data(this, "echoformsInterface", new EchoFormsInterface(this, options))

  $(document).ready ->
    #formatXml = (xml) ->
    #  xml.replace(/\s+/g, ' ').replace(/> </g, '>\n<')

    #$(document).bind 'echoforms:instanceChange', (event, instance) ->
    #  $('#debug').text(formatXml(instance.serialize()))

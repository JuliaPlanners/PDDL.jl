## Workaround to inject custom meta tags into HTML header
# NOTE: This may only work for Documenter 0.27

using Documenter
import Documenter.Writers.HTMLWriter: HTMLWriter
import Documenter.Utilities.DOM: DOM, @tags

struct MetaTaggedHTMLContext
   context::HTMLWriter.HTMLContext
   metatags::Vector{DOM.Node}
end

# Forward all property look-ups to wrapped context
function Base.getproperty(ctx::MetaTaggedHTMLContext, name::Symbol)
   if hasfield(typeof(ctx), name)
      return getfield(ctx, name)
   else
      return getproperty(getfield(ctx, :context), name)
   end
end

function Base.setproperty!(ctx::MetaTaggedHTMLContext, name::Symbol, value)
   if hasfield(typeof(ctx), name)
       return getfield(ctx, name)
   else
      setproperty!(getfield(ctx, :context), name, value)
   end
end

const meta = DOM.Tag(:meta)
const CUSTOM_META_TAGS = DOM.Node[]

# Override default constructor for HTMLContext
function HTMLWriter.HTMLContext(doc::Documenter.Documents.Document,
                                settings::HTMLWriter.HTML)
   @info "HTMLWriter: injecting custom meta tags"
   # Manually invoke original constructor
   context = Core.invoke(HTMLWriter.HTMLContext, Tuple{Any, Any}, doc, settings)
   # Return meta-tagged context
   return MetaTaggedHTMLContext(context, CUSTOM_META_TAGS)
end

# Override how pages are rendered
function HTMLWriter.render_page(ctx::MetaTaggedHTMLContext, navnode)
    @tags html div body
    # Construct HTML header with meta tagged context
    head = HTMLWriter.render_head(ctx, navnode)
    # Construct everything else with original context
    page = HTMLWriter.getpage(ctx.context, navnode)
    sidebar = HTMLWriter.render_sidebar(ctx.context, navnode)
    navbar = HTMLWriter.render_navbar(ctx.context, navnode, true)
    article = HTMLWriter.render_article(ctx.context, navnode)
    footer = HTMLWriter.render_footer(ctx.context, navnode)
    htmldoc = HTMLWriter.render_html(ctx.context, navnode, head, sidebar,
                                     navbar, article, footer)
    HTMLWriter.open_output(ctx, navnode) do io
        print(io, htmldoc)
    end
end

# Override how the search page is rendered
function HTMLWriter.render_search(ctx::MetaTaggedHTMLContext)
    return HTMLWriter.render_search(ctx.context)
end

# Override how the HTML header is rendered
function HTMLWriter.render_head(ctx::MetaTaggedHTMLContext, navnode)
    @tags head meta link script title
    src = HTMLWriter.get_url(ctx, navnode)

    page_title = HTMLWriter.mdflatten(HTMLWriter.pagetitle(ctx, navnode))
    page_title = "$page_title · $(ctx.doc.user.sitename)"
    css_links = [
        HTMLWriter.RD.lato,
        HTMLWriter.RD.juliamono,
        HTMLWriter.RD.fontawesome_css...,
        HTMLWriter.RD.katex_css,
    ]
    head(
        meta[:charset=>"UTF-8"],
        meta[:name => "viewport", :content => "width=device-width, initial-scale=1.0"],

        # NOTE: Custom meta tags are inserted here,
        meta[:name => "og:title", :content => page_title],
        meta[:name => "twitter:title", :content => page_title],
        ctx.metatags...,

        title(page_title),

        HTMLWriter.analytics_script(ctx.settings.analytics),
        HTMLWriter.warning_script(src, ctx),

        HTMLWriter.canonical_link_element(ctx.settings.canonical,
                                          HTMLWriter.pretty_url(ctx, src)),

        # Stylesheets.
        map(css_links) do each
            link[:href => each, :rel => "stylesheet", :type => "text/css"]
        end,

        script("documenterBaseURL=\"$(HTMLWriter.relhref(src, "."))\""),
        script[
            :src => HTMLWriter.RD.requirejs_cdn,
            Symbol("data-main") => HTMLWriter.relhref(src, ctx.documenter_js)
        ],

        script[:src => HTMLWriter.relhref(src, "siteinfo.js")],
        script[:src => HTMLWriter.relhref(src, "../versions.js")],
        # Themes. Note: we reverse the list to make sure that the default theme (first in
        # the array) comes as the last <link> tag.
        map(Iterators.reverse(enumerate(HTMLWriter.THEMES))) do (i, theme)
            e = link[".docs-theme-link",
                :rel => "stylesheet", :type => "text/css",
                :href => HTMLWriter.relhref(src, "assets/themes/$(theme).css"),
                Symbol("data-theme-name") => theme,
            ]
            (i == 1) && push!(e.attributes, Symbol("data-theme-primary") => "")
            (i == 2) && push!(e.attributes, Symbol("data-theme-primary-dark") => "")
            return e
        end,
        script[:src => HTMLWriter.relhref(src, ctx.themeswap_js)],
        # Custom user-provided assets.
        HTMLWriter.asset_links(src, ctx.settings.assets),
    )
end

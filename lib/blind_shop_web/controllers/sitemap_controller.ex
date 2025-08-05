defmodule BlindShopWeb.SitemapController do
  use BlindShopWeb, :controller

  def index(conn, _params) do
    urls = [
      %{
        loc: "https://blindrestoration.com",
        lastmod: Date.utc_today(),
        changefreq: "weekly",
        priority: "1.0"
      },
      %{
        loc: "https://blindrestoration.com/shipping-instructions",
        lastmod: Date.utc_today(),
        changefreq: "monthly",
        priority: "0.8"
      },
      %{
        loc: "https://blindrestoration.com/terms-of-service",
        lastmod: Date.utc_today(),
        changefreq: "yearly",
        priority: "0.3"
      },
      %{
        loc: "https://blindrestoration.com/privacy-policy",
        lastmod: Date.utc_today(),
        changefreq: "yearly",
        priority: "0.3"
      }
    ]

    xml_content = generate_sitemap_xml(urls)
    
    conn
    |> put_resp_content_type("application/xml")
    |> text(xml_content)
  end

  defp generate_sitemap_xml(urls) do
    url_entries = Enum.map(urls, fn url ->
      """
        <url>
          <loc>#{url.loc}</loc>
          <lastmod>#{url.lastmod}</lastmod>
          <changefreq>#{url.changefreq}</changefreq>
          <priority>#{url.priority}</priority>
        </url>
      """
    end)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{Enum.join(url_entries, "")}
    </urlset>
    """
  end
end
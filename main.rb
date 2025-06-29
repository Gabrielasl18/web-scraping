require 'selenium-webdriver'
require 'nokogiri'

def scrape
  puts "Abrindo navegador..."
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  driver = Selenium::WebDriver.for(:chrome, options: options)

  begin
    driver.navigate.to "https://www.samsung.com/br/smartphones/all-smartphones/"
    wait = Selenium::WebDriver::Wait.new(timeout: 10)
    wait.until { driver.find_element(css: '.pd19-product-card__item') }
  rescue => e
    puts "Erro ao carregar a página: #{e.message}"
    driver.quit
    return
  end

  doc = Nokogiri::HTML(driver.page_source)
  products = []

  doc.css('.pd19-product-card__item').each do |card|
    title = card.at_css('.pd19-product-card__name')&.text&.strip
    price = card.at_css('.pd19-product-card__current-price')&.text&.strip

    img_tag = card.at_css('img')
    image = nil

    if img_tag
      image = img_tag['data-desktop-src'] || img_tag['src']
    end

    if image.nil?
      alt_img = card.at_css('.image img')
      image = alt_img['data-desktop-src'] || alt_img['src'] if alt_img
    end

    image = "https:#{image}" if image && !image.start_with?('http')

    products << { title: title, price: price, image: image }
  end

  driver.quit
  puts "#{products.size} produtos encontrados."
  generate_html(products)
end

def generate_html(products)
  html = <<~HTML
    <!DOCTYPE html>
    <html lang="pt-br">
    <head>
      <meta charset="UTF-8" />
      <title>Lista de Smartphones Samsung</title>
      <style>
        body { font-family: Arial, sans-serif; background: #f9f9f9; margin: 2rem; }
        h1 { color: #1428a0; }
        ul { list-style: none; padding: 0; }
        li { background: white; margin: 1rem 0; padding: 1rem; border-radius: 8px; box-shadow: 0 0 5px #ccc; display: flex; align-items: center; gap: 1rem; }
        .info { flex: 1; }
        .price { color: green; font-weight: bold; }
        img { width: 100px; border-radius: 6px; }
      </style>
    </head>
    <body>
      <h1>Smartphones Samsung</h1>
      <ul>
        #{products.map do |p|
          "<li>
            <img src='#{p[:image]}' alt='#{p[:title]}' />
            <div class='info'>
              <strong>#{p[:title] || ''}</strong><br>
              <span class='price'>#{p[:price] || 'Saiba mais'}</span>
            </div>
          </li>"
        end.join("\n")}
      </ul>
    </body>
    </html>
  HTML

  filename = "smartphones_samsung_#{Time.now.strftime('%Y%m%d_%H%M%S')}.html"
  File.write(filename, html)
  puts "Arquivo #{filename} gerado."
  system("xdg-open #{filename}") || system("open #{filename}")
end

scrape

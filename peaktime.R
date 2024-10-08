# 加载必要的包
library(DiagrammeR)
library(DiagrammeRsvg)
library(officer)
library(rsvg)
library(magrittr)
# Set the path to save the SVG file
# Set the path to save the SVG file and the final JPG
svg_path <- "/Users/liaojiajia/博士研究/冲绳/热暴露/heat_exposure_detailed_flowchart.svg"
jpg_path <- "/Users/liaojiajia/博士研究/冲绳/热暴露/heat_exposure_detailed_flowchart.jpg"

# Create the flowchart and save as SVG
grViz("
  digraph heat_exposure_calculation {

    # Set the overall direction of the graph from left to right for a more parallel layout
    graph [rankdir = LR]

    # Define node styles
    node [shape = rectangle, style = filled, fillcolor = \"#FFFFFF\", color = \"#000000\", fontname = \"Times New Roman\", fontsize = 16, fontweight = bold]

    # Node definitions with larger and bold fonts
    A [label = 'Divide city into 250-meter grids\\nbased on LST values']
    B [label = 'Identify home locations\\n(10 PM - 6 AM)', shape = ellipse]
    C [label = 'Identify activity destinations\\n(9 AM - 6 PM)', shape = ellipse]
    D [label = 'Determine movement pathways\\n(Home to Destination)', shape = parallelogram]
    E [label = 'Is stay duration > 1 hour in the grid?', shape = diamond, fillcolor = \"#FFFFFF\"]
    F [label = 'Do not calculate heat exposure for this grid', shape = rectangle, fillcolor = \"#FFFFFF\"]
    G [label = 'Calculate Exposure = Duration x LST', shape = rectangle, fillcolor = \"#FFFFFF\"]
    H [label = 'Calculate total heat exposure along the pathway', shape = rectangle, fillcolor = \"#FFFFFF\"]
    I [label = 'Note: Exclude home and destination grids', shape = plaintext, fontsize = 14, fontcolor = \"#333333\", fontweight = bold]

    # Define edges and relationships
    A -> B [label = 'Analysis mobile data']
    B -> C [label = 'Identify home and destinations']
    C -> D [label = 'Determine movement pathways']
    D -> E [label = 'Evaluate each grid']
    E -> F [label = 'Yes', color = \"#000000\"]
    E -> G [label = 'No', color = \"#000000\"]
    G -> H [label = 'Summarize heat exposure']

    # Connect note to relevant nodes with dashed lines
    I -> B [style = dashed]
    I -> C [style = dashed]
  }
") %>% export_svg() %>% charToRaw() %>% rsvg(width = 3000, height = 2000) -> bitmap

# Convert the SVG to JPG using magick with 300 dpi resolution
image <- image_read(bitmap)  # Read the bitmap from SVG
image_write(image, path = jpg_path, format = "jpg", density = "300x300")  # Write to JPG format with 300 dpi


jpg_path <- "/Users/liaojiajia/博士研究/冲绳/热暴露/flowchart.jpg"
grViz("
  digraph heat_exposure_technical {

    # Set the overall direction of the graph from top to bottom for a vertical layout
    graph [rankdir = TB]

    # Define node styles
    node [shape = rectangle, style = filled, fillcolor = \"#FFFFFF\", color = \"#000000\", fontname = \"Arial\", fontsize = 18, fontweight = bold]

    # Node definitions with larger and bold fonts
    Title [label = 'Heat Risk Zoning', shape = plaintext, fontsize = 22, fontcolor = \"#000000\", fontweight = bold]
    A [label = 'Divide city into high and low risk grids\\n(based on LST > 0.5196)']
    B [label = 'Identify risk level of home and destination\\n(high or low risk)', shape = ellipse]
    C [label = 'Analyze daily movement\\nfrom high and low risk homes', shape = parallelogram]
    D1 [label = 'High risk home to High risk destination', shape = rectangle, fillcolor = \"#FFDDC1\"]
    D2 [label = 'High risk home to Low risk destination', shape = rectangle, fillcolor = \"#FFD700\"]
    D3 [label = 'Low risk home to High risk destination', shape = rectangle, fillcolor = \"#FFD700\"]
    D4 [label = 'Low risk home to Low risk destination', shape = rectangle, fillcolor = \"#C1FFC1\"]
    E [label = 'Classify risk areas', shape = diamond, fillcolor = \"#FFFFFF\"]
    F1 [label = 'Double High: Extreme High Temperature Zone', shape = rectangle, fillcolor = \"#FF4500\", fontcolor = \"#FFFFFF\"]
    F2 [label = 'High-Low & Low-High: Potential Risk Zone', shape = rectangle, fillcolor = \"#FFA500\"]
    F3 [label = 'Double Low: No Risk Zone', shape = rectangle, fillcolor = \"#32CD32\"]
    G [label = 'Heat Mitigation Strategies', shape = rectangle, fillcolor = \"#FFFFFF\"]
    G1 [label = 'Construct SLM model\\n(using NDVI and distance to water)', shape = rectangle, fillcolor = \"#E0E0E0\"]
    G2 [label = 'Simulate scenarios', shape = diamond, fillcolor = \"#FFFFFF\"]
    G3 [label = 'Scenario 1: Increased NDVI in all city', shape = rectangle, fillcolor = \"#C1E1FF\"]
    G4 [label = 'Scenario 2: Increased NDVI in zoning', shape = rectangle, fillcolor = \"#C1FFC1\"]
    G5 [label = 'Quantify impact of vegetation increase\\non heat exposure', shape = rectangle, fillcolor = \"#FFFFFF\"]
    
    # Define edges and relationships
    Title -> A
    A -> B [label = 'Define risk based on LST']
    B -> C [label = 'Identify risk levels']
    C -> D1 [label = 'Daily movement']
    C -> D2
    C -> D3
    C -> D4
    D1 -> E [label = 'Classify by movement']
    D2 -> E
    D3 -> E
    D4 -> E
    E -> F1 [label = 'Double High', color = \"#FF4500\"]
    E -> F2 [label = 'High-Low & Low-High', color = \"#FFA500\"]
    E -> F3 [label = 'Double Low', color = \"#32CD32\"]
    F1 -> G [label = 'Use SLM model']
    F2 -> G
    F3 -> G
    G -> G1 [label = 'Construct model']
    G1 -> G2 [label = 'Define scenarios']
    G2 -> G3 [label = 'Scenario 1']
    G2 -> G4 [label = 'Scenario 2']
    G3 -> G5 [label = 'Evaluate impact']
    G4 -> G5 [label = 'Evaluate impact']
  }
") %>% export_svg() %>% charToRaw() %>% rsvg(width = 3000, height = 4000) -> bitmap

# Convert the SVG to JPG using magick with 300 dpi resolution
image <- image_read(bitmap)  # Read the bitmap from SVG
image_write(image, path = jpg_path, format = "jpg", density = "300x300")  # Write to JPG format with 300 dpi





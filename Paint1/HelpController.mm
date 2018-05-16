#import "HelpController.h"
#import "QuartzView.h"
#import "Persist.h"

NSString* htmlString =
@"<html>"
    "<head>"
        "<STYLE TYPE=\"text/css\">"
            "<!--"
            "TABLE{ cellpadding=3 }"
            "TD{font-family: Arial; font-size: 10pt; }"
            "--->"
            "</STYLE>"
        "</head>"
    
    "<body BGCOLOR=\"black\">"
        "<FONT COLOR=white>"
            "<p style='font-size:14px'>"
            "<table>"
                "<tr><td style=width:36px><FONT COLOR=white>Code</td><td><FONT COLOR=white>Component (Press character code to add component to circuit)</td></tr>"
                "<tr><td><FONT COLOR=green>1</td><td><p style=color:lightblue>Resistor ( 'K' is appended to name if no suffix specified )</td></tr>"
                "<tr><td><FONT COLOR=green>2</td><td><FONT COLOR=lightblue>Capacitor ( 'Shift-2' for E Cap )</td></tr>"
                "<tr><td><FONT COLOR=green>3</td><td><FONT COLOR=lightblue>Connection Node</td></tr>"
                "<tr><td><FONT COLOR=green>4</td><td><FONT COLOR=lightblue>Ground Point. 'W' sets Gnd to Waypoint</td></tr>"
                "<tr><td><FONT COLOR=green>5</td><td><FONT COLOR=lightblue>Waypoint. 'G' sets waypoint to Gnd</td></tr>"
                "<tr><td><FONT COLOR=green>6</td><td><FONT COLOR=lightblue>Transistor</td></tr>"
                "<tr><td><FONT COLOR=green>7</td><td><FONT COLOR=lightblue> 8 pin Chip  ( 'Shift-7' for 18 pin Chip )</td></tr>"
                "<tr><td><FONT COLOR=green>8</td><td><FONT COLOR=lightblue>14 pin Chip</td></tr>"
                "<tr><td><FONT COLOR=green>9</td><td><FONT COLOR=lightblue>16 pin Chip  ( 'Shift-9' for 40 pin Chip )</td></tr>"
                "<tr><td><FONT COLOR=green>0</td><td><FONT COLOR=lightblue>Power connector</td></tr>"
                "<tr><td><FONT COLOR=green>!</td><td><FONT COLOR=lightblue>Trimmer</td></tr>"
                "<tr><td><FONT COLOR=green>D</td><td><FONT COLOR=lightblue>Diode</td></tr>"
                "<tr><td><FONT COLOR=green>O</td><td><FONT COLOR=lightblue>OpAmp</td></tr>"
                "<tr><td><FONT COLOR=green>P</td><td><FONT COLOR=lightblue>Pot</td></tr>"
                "</table>"
            "<br>"
            "</FONT>"
        
        "<FONT COLOR=white>"
            "Program State<br>"
            "<table>"
                "<tr><td style=width:36px><FONT COLOR=green>M</td><td style=width:180px><FONT COLOR=lightblue>Move mode</td><td><FONT COLOR=yellow>Move selected component(s) with mouse and arrow keys.</td></tr>"
                "<tr><td><FONT COLOR=green>C</td>      <td><FONT COLOR=lightblue>Add Connections mode</td><td><FONT COLOR=yellow>Click on two nodes/pins to connect.    Use 'Shift-C' for 'flying wire' style.</td></tr>"
                "<tr><td><FONT COLOR=green>Z</td>      <td><FONT COLOR=lightblue>Delete Connections mode</td><td><FONT COLOR=yellow>Left click on center of connection line to delete.</td></tr>"
                "<tr><td><FONT COLOR=green>Q</td>      <td><FONT COLOR=lightblue>Start Multi Select mode</td><td><FONT COLOR=yellow>Drag selection rectangle over components to select. Drag multiple times to add more components.</td></tr>"
                "<tr><td><FONT COLOR=green>I</td>      <td><FONT COLOR=lightblue>Info mode</td><td><FONT COLOR=yellow>Click on a node to highlight its' connections.</td></tr>"
                "<tr><td><FONT COLOR=green>L</td>      <td><FONT COLOR=lightblue>Look mode</td><td><FONT COLOR=yellow>Click on a node to highlight other nodes with same name.</td></tr>"
                "<tr><td><FONT COLOR=green>R</td>      <td><FONT COLOR=lightblue>Check mode</td><td><FONT COLOR=yellow>Left click on components, and right click on connections to toggle their 'checked' status.</td></tr>"
                "</table>"
            "<br>"
            "</FONT>"
        
        "<FONT COLOR=white>"
            "Commands<br>"
            "<table>"
                "<tr>"
                    "<td style=width:36px><FONT COLOR=green>=</td><td style=width:450px><FONT COLOR=lightblue>Toggle zoom ( use '<','>'  to alter zoom level )</td>"
                    "<td><FONT COLOR=white>Notes</td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>V</td>  <td><FONT COLOR=lightblue>Cycle View style.  'Shift-V' toggles Via display during design view.</td>"
                    "<td><FONT COLOR=yellow>Click on upper left pin of component to select it</td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>F</td>  <td><FONT COLOR=lightblue>Rotate component</td>"
                    "<td><FONT COLOR=yellow>'E' + mouseWheel resizes Resistors and Caps</td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>N</td>  <td><FONT COLOR=lightblue>Rename component (comma in name starts 2nd line)</td>"
                    "<td><FONT COLOR=yellow>'S' = shortcut to Save circuit, 'Shift-S'  saves to last used filename. 'Shift-O' shortcut to Open</td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>X</td>  <td><FONT COLOR=lightblue>Exchange pins (Resistors, Caps, Diodes)</td>"
                    "<td><FONT COLOR=yellow>'Shift-G' toggles grid display</td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>A</td>  <td><FONT COLOR=lightblue>Clone selected component(s)</td>"
                    "<td><FONT COLOR=yellow>'?' = shortcut to launch this popup</td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>H</td>  <td><FONT COLOR=lightblue>Search for component by name</td>"
                    "<td></td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>Y</td>  <td><FONT COLOR=lightblue>Save selected components to clipboard.  Use 'Shift-Y' to paste clipboard</td>"
                    "<td><FONT COLOR=green>Move mode: Press 'Space' to delete selected component</td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>W</td>  <td><FONT COLOR=lightblue>Change selected component to a waypoint</td>"
                    "<td><FONT COLOR=green>Move mode: Right click on a connection line to intersperse a waypoint</td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>.</td>  <td><FONT COLOR=lightblue>Cycle through board sizes</td>"
                    "<td><FONT COLOR=green>Move mode: Right click on a waypoint to remove it.   Left click on connection to remove it.</td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>J</td>  <td><FONT COLOR=lightblue>Flip X coordinates of multi-Selected</td>"
                    "<td><FONT COLOR=green>Move mode: Right clicking 'in air' will cycle through add connection, delete connection and move modes</td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>Spc</td><td><FONT COLOR=lightblue>Delete current component   ( 'Shift + Spc' deletes multiselected )</td>"
                    "<td><FONT COLOR=green>Move mode: Click on connection line center to delete it</td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>?,/</td><td><FONT COLOR=lightblue>Launch this dialog</td>"
                    "<td><FONT COLOR=green>Move mode: 'Ctrl + N' to change current component name to match previously selected component</td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>U</td>  <td><FONT COLOR=lightblue>Undo</td>"
                    "<td></td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>B</td>  <td><FONT COLOR=lightblue>Cycle BOM display ( normal, verbose, none )</td>"
                    "<td><FONT COLOR=yellow>In zoomed view: mouse wheel (and 'Shift + mousewheel') scroll the circuit</td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>$</td>  <td><FONT COLOR=lightblue>Toggle Rotate 90deg (for zoomed screen captures)</td>"
                    "<td><FONT COLOR=yellow>In multi-select mode: click/drag over additional components to add to group</td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>%</td>  <td><FONT COLOR=lightblue>Add legend text</td>"
                    "<td><FONT COLOR=yellow>Text is displayed flipped, ready for use on PCB mask.  Grab text by right edge.</td>"
                    "</tr>"
                "<tr>"
                    "<td><FONT COLOR=green>;</td>  <td><FONT COLOR=lightblue>Toggle Description display</td>"
                    "<td><FONT COLOR=yellow>Text after a ';' in a label is the description (such as resistor name, etc).</td>"
                    "</tr>"
                "</table>"
            "</FONT>"
        "</body>"
    "</html>";

@implementation HelpController

- (void)viewDidLoad
{
[super viewDidLoad];
[[_webView mainFrame] loadHTMLString:htmlString baseURL:[[NSBundle mainBundle] bundleURL]];
}

- (IBAction)OpenButtonPressed:(id)sender
{
q.openDocument();
}

- (IBAction)saveButtonPressed:(id)senderZ
{
q.saveDocument();
}

- (IBAction)resetButtonPressed:(id)sender
{
[quartzView reset];
}

@end

# subXtract-sh

### Disclaimer
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\
SOFTWARE.

### Information
subXtract-sh is a bash script to copy .srt files and extracting subtitles from .mkv, .mp4 and .avi files using FFmpeg and FFprobe.\
subXtract-sh makes it easy to copy and extract multiple subtitles from a directory and its sub directories.\
subXtract-sh extracts all subtitles from media files and adds language to subtitle file name.\
subXtract-sh does not overwrite files.\
subXtract-sh has currently only support for text based subtitles.

## Usage
```
./subxtract.sh [-i inpath -o outdir] [options]
```

### Help
```
./subxtract.sh -h
```

### License
```
./subxtract.sh -l
```

## Options
|Options|Description|
|-:|-|
|-h|Show help|
|-v|Show version|
|-l|Show license|
|-i inpath|Specify path to input, file or directory. Default: Same directory where this script is located|
|-o outdir|Specify path to output directory. Default: Same directory where the file is found|
|-r|Scan a directory recursively|
|-c|Copy only|
|-e|Extract only|
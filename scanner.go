package main

import (
	"bufio"
	"encoding/csv"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/cloudflare/ahocorasick"
	"golang.org/x/exp/mmap"
)

const (
	maxFileSize      = 20 * 1024 * 1024
	progressBarWidth = 40
)

type result struct {
	id      int64
	path    string
	match   string
	modTime string
}

type fileEntry struct {
	path    string
	modTime time.Time
}

func main() {
	printBanner()

	maxGoroutines := 2 * runtime.NumCPU()

	searchStrings := getSearchStrings()
	if len(searchStrings) == 0 {
		fmt.Println("No search strings entered. Exiting.")
		return
	}

	matcher := ahocorasick.NewStringMatcher(searchStrings)

	now := time.Now().Format("2006-01-02-15-04")
	desktop := os.Getenv("USERPROFILE") + `\\Desktop`
	outCsv := fmt.Sprintf("%s\\FullScan-%s.csv", desktop, now)

	csvFile, err := os.Create(outCsv)
	if err != nil {
		fmt.Println("Error creating CSV file:", err)
		return
	}
	defer csvFile.Close()

	csvWriter := csv.NewWriter(csvFile)
	defer csvWriter.Flush()

	csvWriter.Write([]string{"#", "File Path", "Matched String", "Last Modified"})

	drives := getDrives()
	userProfile := strings.ToLower(os.Getenv("USERPROFILE"))

	excludeDirs := map[string]bool{
		"c:\\windows":                    true,
		"c:\\windows\\system32":          true,
		"c:\\program files":              true,
		"c:\\program files (x86)":        true,
		"c:\\programdata":                true,
		userProfile + "\\appdata":        true,
		"c:\\games":                      true,
		"c:\\program files\\steam":       true,
		"c:\\program files (x86)\\steam": true,
		"c:\\program files\\epic games":  true,
	}
	var files []fileEntry
	for _, drive := range drives {
		filepath.WalkDir(drive, func(path string, d os.DirEntry, err error) error {
			if err != nil {
				return nil
			}
			lowerPath := strings.ToLower(path)
			for exclude := range excludeDirs {
				if strings.HasPrefix(lowerPath, exclude) {
					return filepath.SkipDir
				}
			}
			if !d.IsDir() {
				ext := strings.ToLower(filepath.Ext(d.Name()))
				if ext == ".exe" || ext == ".py" || ext == ".jar" || ext == ".dll" || ext == ".bat" {
					info, err := d.Info()
					if err == nil && info.Size() <= maxFileSize {
						files = append(files, fileEntry{path: path, modTime: info.ModTime()})
					}
				}
			}
			return nil
		})
	}

	total := len(files)
	fmt.Printf("Found %d files. Starting scan...\n", total)

	sem := make(chan struct{}, maxGoroutines)
	resultsChan := make(chan result, 1000)

	var wg sync.WaitGroup
	var rowCounter int64 = 1
	var foundCount int64 = 0
	startTime := time.Now()

	go func() {
		for res := range resultsChan {
			csvWriter.Write([]string{
				fmt.Sprintf("%d", res.id), res.path, res.match, res.modTime,
			})
		}
	}()

	for idx, file := range files {
		sem <- struct{}{}
		wg.Add(1)

		go func(f fileEntry, i int) {
			defer func() {
				<-sem
				wg.Done()
			}()

			reader, err := mmap.Open(f.path)
			if err != nil {
				return
			}
			defer reader.Close()

			data := make([]byte, reader.Len())
			_, err = reader.ReadAt(data, 0)
			if err != nil {
				return
			}

			lowerData := []byte(strings.ToLower(string(data)))

			matches := matcher.Match(lowerData)
			seen := map[int]bool{}
			for _, m := range matches {
				if seen[m] {
					continue
				}
				seen[m] = true
				id := atomic.AddInt64(&rowCounter, 1)
				atomic.AddInt64(&foundCount, 1)
				resultsChan <- result{
					id:      id,
					path:    f.path,
					match:   searchStrings[m],
					modTime: f.modTime.Format("2006-01-02 15:04:05"),
				}
			}

			progress := float64(i+1) / float64(total) * 100
			elapsed := time.Since(startTime).Seconds()
			eta := getETA(elapsed, i+1, total)

			printProgress(progress, i+1, total, eta, atomic.LoadInt64(&foundCount))
		}(file, idx)
	}

	wg.Wait()
	close(resultsChan)

	fmt.Printf("\nScan completed. Results saved to: %s\n", outCsv)
}

func printBanner() {
	fmt.Println()
	fmt.Println("╔════════════════════════════════════╗")
	fmt.Println("║         VORTEX SCANNER             ║")
	fmt.Println("╚════════════════════════════════════╝")
	fmt.Println("           made by bridgezan          ")
	fmt.Println()
}

func getDrives() []string {
	drives := []string{}
	for _, d := range "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
		drive := string(d) + ":\\"
		if _, err := os.Stat(drive); err == nil {
			drives = append(drives, drive)
		}
	}
	return drives
}

func getSearchStrings() []string {
	reader := bufio.NewReader(os.Stdin)
	fmt.Println("Use default search strings? (Y/N)")
	choice, _ := reader.ReadString('\n')
	choice = strings.TrimSpace(strings.ToLower(choice))

	if choice != "y" {
		fmt.Println("Enter your keywords (type 'done' to finish):")
		var result []string
		for {
			line, _ := reader.ReadString('\n')
			line = strings.TrimSpace(line)
			if line == "done" {
				break
			}
			if line != "" {
				result = append(result, strings.ToLower(line))
			}
		}
		return result
	}

	fmt.Println("Do you want full(1) scan or fast(2) scan? (1/2)")
	mode, _ := reader.ReadString('\n')
	mode = strings.TrimSpace(strings.ToLower(mode))

	shortList := []string{
		"mouse_event", "pyautogui", ".amogus", "onclicklistener()",
		"autoclicker.class", "uwu.class", "if(isclicking)", ".mousepress", "@suvwatauvawh",
		"uiaccess='false'", "reeach", "autoclicker", "[bind:",
		"key_key.", "autoclicker", "killaura", "dreamagent",
		"veracrypt", "makecert", "jnativehook", "vape.gg", "aimbot",
		"aimbot", "tracers", "tracers", "[bind",
		"lclick", "rclick", "fastplace", "self destruct", "slinky",
	}

	fullList := []string{
		"slinky", "doomsday", "sapphire", "pvpxd", "toad",
		"recorder", "nemui", "lithium", "kura", "dusk",
		"raid0", "prism", "axenta", "icetea", "tuke", "koid",
		"ecstacy", "itami", "epic", "krypton", "exelon", "hermotet",
		"asterion", "karma", "zyklon",
	}

	if mode == "2" {
		return shortList
	} else if mode == "1" {
		return append(fullList, shortList...)
	} else {
		fmt.Println("Invalid option, defaulting to full scan.")
		return append(fullList, shortList...)
	}
}

func printProgress(progress float64, current, total int, eta string, found int64) {
	done := int(progress / 100 * float64(progressBarWidth))
	bar := strings.Repeat("=", done) + strings.Repeat(" ", progressBarWidth-done)
	fmt.Printf("[%s] %.1f%%  Files: %d/%d  Found: %d  ETA: %s\r",
		bar, progress, current, total, found, eta)
}

func getETA(elapsedSeconds float64, current, total int) string {
	if current == 0 {
		return "calculating..."
	}
	remaining := elapsedSeconds / float64(current) * float64(total-current)
	if remaining < 0 {
		remaining = 0
	}

	h := int(remaining) / 3600
	m := (int(remaining) % 3600) / 60
	s := int(remaining) % 60

	if h > 0 {
		return fmt.Sprintf("%02d:%02d:%02d", h, m, s)
	}
	return fmt.Sprintf("%02d:%02d", m, s)
}

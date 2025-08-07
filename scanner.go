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
	fmt.Println("======= Vortex Scanner =======")

	reader := bufio.NewReader(os.Stdin)
	fmt.Print("Scan system32? (Y/N): ")
	sysChoice, _ := reader.ReadString('\n')
	sysChoice = strings.ToLower(strings.TrimSpace(sysChoice))
	scanSystem32 := sysChoice == "y"

	fmt.Print("Use default file types (.exe .py .ps1)? (Y/N): ")
	extChoice, _ := reader.ReadString('\n')
	extChoice = strings.ToLower(strings.TrimSpace(extChoice))

	var extensions []string
	if extChoice == "y" {
		extensions = []string{".exe", ".py", ".ps1"}
	} else {
		fmt.Println("Enter extensions (type 'done' to finish):")
		for {
			line, _ := reader.ReadString('\n')
			line = strings.ToLower(strings.TrimSpace(line))
			if line == "done" {
				break
			}
			if line != "" && strings.HasPrefix(line, ".") {
				extensions = append(extensions, line)
			}
		}
	}

	fmt.Print("Use default search strings? (Y/N): ")
	strChoice, _ := reader.ReadString('\n')
	strChoice = strings.ToLower(strings.TrimSpace(strChoice))

	var searchStrings []string
	if strChoice == "y" {
		searchStrings = []string{
			"autoclicker", "mouse_event", "killaura", "pyautogui",
			".amogus", "onclicklistener()",
			"autoclicker.class", "uwu.class", "if(isclicking)", ".mousepress", "@suvwatauvawh",
			"uiaccess='false'", "reeach", "[bind:",
			"key_key.", "dreamagent",
			"veracrypt", "makecert", "jnativehook", "vape.gg", "aimbot",
			"tracers", "[bind",
			"lclick", "rclick", "fastplace", "self destruct", "slinky",
		}
	} else {
		fmt.Println("Enter search strings one per line (type 'done' to finish):")
		for {
			line, _ := reader.ReadString('\n')
			line = strings.ToLower(strings.TrimSpace(line))
			if line == "done" {
				break
			}
			if line != "" {
				searchStrings = append(searchStrings, line)
			}
		}
	}

	if len(searchStrings) == 0 || len(extensions) == 0 {
		fmt.Println("No search strings or extensions provided. Exiting.")
		return
	}

	fmt.Print("Save results in separate files per keyword? (Y/N): ")
	splitChoice, _ := reader.ReadString('\n')
	splitChoice = strings.ToLower(strings.TrimSpace(splitChoice))
	splitPerKeyword := splitChoice == "y"

	outputDir := filepath.Join(os.Getenv("USERPROFILE"), "Desktop")
	if splitPerKeyword {
		outputDir = filepath.Join(outputDir, "scanner")
		os.MkdirAll(outputDir, os.ModePerm)
	}

	matcher := ahocorasick.NewStringMatcher(searchStrings)

	var excludeDirs []string
	if !scanSystem32 {
		excludeDirs = append(excludeDirs, `c:\windows\system32`)
	}

	var files []fileEntry
	for _, drive := range getDrives() {
		filepath.WalkDir(drive, func(path string, d os.DirEntry, err error) error {
			if err != nil {
				return nil
			}
			lower := strings.ToLower(path)
			for _, excl := range excludeDirs {
				if strings.HasPrefix(lower, excl) {
					return filepath.SkipDir
				}
			}
			if !d.IsDir() {
				ext := strings.ToLower(filepath.Ext(d.Name()))
				for _, targetExt := range extensions {
					if ext == targetExt {
						info, err := d.Info()
						if err == nil && info.Size() <= 20*1024*1024 {
							files = append(files, fileEntry{path, info.ModTime()})
						}
					}
				}
			}
			return nil
		})
	}

	if len(files) == 0 {
		fmt.Println("No matching files found.")
		return
	}

	var rowID int64 = 1
	var foundCount int64 = 0
	startTime := time.Now()

	resultsMap := make(map[string][]result)
	var mu sync.Mutex

	var wg sync.WaitGroup
	sem := make(chan struct{}, 2*runtime.NumCPU())

	for idx, f := range files {
		wg.Add(1)
		sem <- struct{}{}
		go func(i int, fe fileEntry) {
			defer func() { <-sem; wg.Done() }()

			reader, err := mmap.Open(fe.path)
			if err != nil {
				return
			}
			defer reader.Close()

			data := make([]byte, reader.Len())
			_, err = reader.ReadAt(data, 0)
			if err != nil {
				return
			}

			lower := []byte(strings.ToLower(string(data)))
			matches := matcher.Match(lower)
			seen := map[int]bool{}

			for _, m := range matches {
				if seen[m] {
					continue
				}
				seen[m] = true
				id := atomic.AddInt64(&rowID, 1)
				atomic.AddInt64(&foundCount, 1)

				res := result{
					id:      id,
					path:    fe.path,
					match:   searchStrings[m],
					modTime: fe.modTime.Format("2006-01-02 15:04:05"),
				}

				mu.Lock()
				resultsMap[searchStrings[m]] = append(resultsMap[searchStrings[m]], res)
				mu.Unlock()
			}

			if (i+1)%50 == 0 || i == len(files)-1 {
				fmt.Printf("\rScanned %d/%d files | Found: %d", i+1, len(files), atomic.LoadInt64(&foundCount))
			}
		}(idx, f)
	}

	wg.Wait()
	fmt.Println()

	if splitPerKeyword {
		for s, results := range resultsMap {
			if len(results) == 0 {
				continue
			}
			safeName := strings.ReplaceAll(s, " ", "_")
			outPath := filepath.Join(outputDir, safeName+".csv")

			f, err := os.Create(outPath)
			if err != nil {
				fmt.Println("Error creating file for", s, ":", err)
				continue
			}

			w := csv.NewWriter(f)
			w.Write([]string{"#", "File Path", "Matched String", "Last Modified"})

			for _, r := range results {
				w.Write([]string{
					fmt.Sprint(r.id),
					r.path,
					r.match,
					r.modTime,
				})
			}

			w.Flush()
			f.Close()
		}
	} else {
		// Single file case
		outPath := filepath.Join(outputDir, fmt.Sprintf("FullScan-%s.csv", time.Now().Format("2006-01-02-15-04")))
		f, err := os.Create(outPath)
		if err != nil {
			fmt.Println("Failed to create output file:", err)
			return
		}
		defer f.Close()

		w := csv.NewWriter(f)
		w.Write([]string{"#", "File Path", "Matched String", "Last Modified"})

		for _, results := range resultsMap {
			for _, r := range results {
				w.Write([]string{
					fmt.Sprint(r.id),
					r.path,
					r.match,
					r.modTime,
				})
			}
		}

		w.Flush()
	}

	duration := time.Since(startTime)
	fmt.Printf("Done. Scan took %s\n", duration)
}

func getDrives() []string {
	var drives []string
	for _, c := range "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
		drive := string(c) + ":\\"
		if _, err := os.Stat(drive); err == nil {
			drives = append(drives, drive)
		}
	}
	return drives
}

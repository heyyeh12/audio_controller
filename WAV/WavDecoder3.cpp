/* modified from 
http://stackoverflow.com/questions/13660777/c-reading-the-data-part-of-a-wav-file
http://stackoverflow.com/questions/18771375/c-reading-16bit-wav-file?rq=1
 */
#include <iostream>
#include <string>
#include <fstream>
#include <cstdint>
#include <iomanip>
#include <stdio.h>

using std::cin;
using std::cout;
using std::hex;
using std::setfill;
using std::setw;
using std::endl;
using std::fstream;
using std::string;

typedef struct  WAV_HEADER
{
    /* RIFF Chunk Descriptor */
    uint8_t         RIFF[4];        // RIFF Header Magic header
    uint32_t        ChunkSize;      // RIFF Chunk Size
    uint8_t         WAVE[4];        // WAVE Header
    /* "fmt" sub-chunk */
    uint8_t         fmt[4];         // FMT header
    uint32_t        Subchunk1Size;  // Size of the fmt chunk
    uint16_t        AudioFormat;    // Audio format 1=PCM,6=mulaw,7=alaw,     257=IBM Mu-Law, 258=IBM A-Law, 259=ADPCM
    uint16_t        NumOfChan;      // Number of channels 1=Mono 2=Sterio
    uint32_t        SamplesPerSec;  // Sampling Frequency in Hz
    uint32_t        bytesPerSec;    // bytes per second
    uint16_t        blockAlign;     // 2=16-bit mono, 4=16-bit stereo
    uint16_t        bitsPerSample;  // Number of bits per sample
    /* "data" sub-chunk */
    uint8_t         Subchunk2ID[4]; // "data"  string
    uint32_t        Subchunk2Size;  // Sampled data length
} wav_hdr;

// Function prototypes
int getFileSize(FILE* inFile);

int main(int argc, char* argv[])
{

    wav_hdr wavHeader;
    int headerSize = sizeof(wav_hdr), filelength = 0;

    const char* filePath;
    string arrayName, tableName;
    string input, input1, input2;
    if (argc <= 1)
    {
        cout << "Input wave file name: ";
        cin >> input;
        cin.get();
        filePath = input.c_str();
        cout << "Input array name: ";
        cin >> input1;
        cin.get();
        arrayName = input1.c_str();
        cout << "Input table name: ";
        cin >> input2;
        cin.get();
        tableName = input2.c_str();
    }
    else
    {
        filePath = argv[1];
        cout << "Input wave file name: " << filePath << endl;
    }

    FILE* wavFile = fopen(filePath, "r");
    if (wavFile == nullptr)
    {
        fprintf(stderr, "Unable to open wave file: %s\n", filePath);
        return 1;
    }
    string fp(tableName);
    std::ofstream outfile (fp+".txt");
    //Read the header
    size_t bytesRead = fread(&wavHeader, 1, headerSize, wavFile);
    cout << "Header Read " << bytesRead << " bytes." << endl;
    if (bytesRead > 0)
    {
        //Read the data
        uint16_t bytesPerSample = wavHeader.bitsPerSample / 8;      //Number     of bytes per sample
        uint64_t numSamples = wavHeader.ChunkSize / bytesPerSample; //How many samples are in the wav file?
        static const uint16_t BUFFER_SIZE = 4096;
        int8_t* buffer = new int8_t[BUFFER_SIZE];
 

        cout << "File is                    :" << filelength << " bytes." << endl;
        cout << "RIFF header                :" << wavHeader.RIFF[0] << wavHeader.RIFF[1] << wavHeader.RIFF[2] << wavHeader.RIFF[3] << endl;
        cout << "WAVE header                :" << wavHeader.WAVE[0] << wavHeader.WAVE[1] << wavHeader.WAVE[2] << wavHeader.WAVE[3] << endl;
        cout << "FMT                        :" << wavHeader.fmt[0] << wavHeader.fmt[1] << wavHeader.fmt[2] << wavHeader.fmt[3] << endl;
        cout << "Data size                  :" << wavHeader.ChunkSize << endl;

        // Display the sampling Rate from the header
        cout << "Sampling Rate              :" << wavHeader.SamplesPerSec << endl;
        cout << "Number of bits used        :" << wavHeader.bitsPerSample << endl;
        cout << "Number of channels         :" << wavHeader.NumOfChan << endl;
        cout << "Number of bytes per second :" << wavHeader.bytesPerSec << endl;
        cout << "Data length                :" << wavHeader.Subchunk2Size << endl;
        cout << "Audio Format               :" << wavHeader.AudioFormat << endl;
        // Audio format 1=PCM,6=mulaw,7=alaw, 257=IBM Mu-Law, 258=IBM A-Law, 259=ADPCM

        cout << "Block align                :" << wavHeader.blockAlign << endl;
        cout << "Data string                :" << wavHeader.Subchunk2ID[0] << wavHeader.Subchunk2ID[1] << wavHeader.Subchunk2ID[2] << wavHeader.Subchunk2ID[3] << endl;       
    
        cout << "Data                       :" << endl;


        
        outfile << "type " << arrayName << " is array (0 to " << wavHeader.Subchunk2Size/3 << ") of std_logic_vector(SOUND_BIT_WIDTH-1 downto 0);" << endl;
        outfile << "constant " << tableName << " : sound_table_3 :=" << endl;
        outfile << "(" << endl;
        int totalBytes = 0;
        while ((bytesRead = fread(buffer, sizeof buffer[0], BUFFER_SIZE / (sizeof buffer[0]), wavFile)) > 0)
        {
            totalBytes+= bytesRead;
            //cout << "Read " << bytesRead << " bytes." << endl;
            for (int i = 0; i < bytesRead; i+=3)
            {
                outfile << "x\"";
                outfile << std::setfill('0') << std::uppercase << std::hex << std::setw(2) << (0xFF & buffer[i+2]);
                outfile << std::setfill('0') << std::uppercase << std::hex << std::setw(2) << (0xFF & buffer[i+1]);
                outfile << std::setfill('0') << std::uppercase << std::hex << std::setw(2) << (0xFF & buffer[i]);
                outfile << "\", ";

                // big endian
                //printf(" x\"%02x", (unsigned)(unsigned char)buffer[i]);
                //printf("%02x", (unsigned)(unsigned char)buffer[i+1]);
                //printf("%02x\", ", (unsigned)(unsigned char)buffer[i+2]);

                // little endian
                // printf(" x\"%02x", (unsigned)(unsigned char)buffer[i+2]);
                // printf("%02x", (unsigned)(unsigned char)buffer[i+1]);
                // printf("%02x\", ", (unsigned)(unsigned char)buffer[i]);
                
                // outfile << boost::format(" x\"%02x") % (unsigned)(unsigned char)buffer[i+2];
                // outfile << boost::format("%02x") % (unsigned)(unsigned char)buffer[i+1];
                // outfile << boost::format("%02x\", " % (unsigned)(unsigned char)buffer[i];
                

                if (i % 16 == 0) outfile << endl;
            }
            //cout << endl << endl;
        }
        outfile << ");" << endl;
        outfile.close();
        
        cout << "total bytes                :" << totalBytes << endl;

        delete [] buffer;
        buffer = nullptr;

        filelength = getFileSize(wavFile);

        cout << "filelength                 :" << filelength << endl;

    }
    fclose(wavFile);
    return 0;
}

// find the file size
int getFileSize(FILE* inFile)
{
    int fileSize = 0;
    fseek(inFile, 0, SEEK_END);

    fileSize = ftell(inFile);

    fseek(inFile, 0, SEEK_SET);
    return fileSize;
}